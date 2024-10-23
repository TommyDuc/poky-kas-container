repo_root := absolute_path(justfile_directory())
repo_name := file_name(repo_root)

dotenv := repo_root / ".env"

# Use either "podman" or "docker" here.
# Override as follow: `$ just cli_exe=docker image`.
cli_exe := "podman"

registry_name := "docker.io"
image_name := "dimonoff/poky-kas-container"
image_fqn := registry_name / image_name

cntr_repo_root := "/workdir"
cntr_name := repo_name + "-instance"
# Override as follow: `$ just cntr_cmd=my-cmd run`.
cntr_cmd := "bash"

cli_run_extra_opts := if "podman" == cli_exe { cli_run_extra_opts_podman } else { cli_run_extra_opts_default }
# Prevent the "The uid:gid for "/workdir" is "0:0". The uid and gid must be non-zero." error.
# More details at <https://docs.podman.io/en/v4.4/markdown/options/userns.container.html>.
cli_run_extra_opts_podman := "--userns=keep-id:uid=1000,gid=100"
cli_run_extra_opts_default := ""

# Use the dotenv / env value by default.
# Override as follow: `$ just img_dist=my-distro-tag image`.
img_dist := "${DISTRO_CROPS_POKY:?}"
# Use the dotenv / env value by default.
# Override as follow: `$ just img_kas=my-kas-version image`.
img_kas := "${KAS_VERSION:?}"
# Use the dotenv / env value by default.
# Override as follow: `$ just img_sfx=-my-distro-variant-suffix image`.
img_sfx := "${IMAGE_SUFFIX:-}"

default: image

clean: image-clean env-file-clean

reset: env-file-reset

login:
    @{{ cli_exe }} login "{{ registry_name }}"

logout:
    @{{ cli_exe }} logout "{{ registry_name }}"

image dist=img_dist kas=img_kas sfx=img_sfx: init
    @. "{{ dotenv }}" && \
    img_dist="{{ dist }}" && \
    img_kas="{{ kas }}" && \
    img_sfx="{{ sfx }}" && \
    img_tag="${img_dist}-kas-${img_kas}${img_sfx}" && \
    {{ cli_exe }} build \
      --build-arg "DISTRO_CROPS_POKY=${img_dist}" \
      --build-arg "KAS_VERSION=${img_kas}" \
      --tag "{{ image_fqn }}:${img_tag}" \
      --file "Containerfile" \
      "{{ repo_root }}"

image-clean: run-clean
    @{{ cli_exe }} images -q --filter "reference={{ image_name }}" \
    | sort | uniq \
    | xargs --no-run-if-empty {{ cli_exe }} rmi -f

image-publish dist=img_dist kas=img_kas sfx=img_sfx: (image dist kas sfx)
    @. "{{ dotenv }}" && \
    img_dist="{{ dist }}" && \
    img_kas="{{ kas }}" && \
    img_sfx="{{ sfx }}" && \
    img_tag="${img_dist}-kas-${img_kas}${img_sfx}" && \
    {{ cli_exe }} push "{{ image_fqn }}:${img_tag}"

run cmd=cntr_cmd dist=img_dist kas=img_kas sfx=img_sfx: (image dist kas sfx)
    @. "{{ dotenv }}" && \
    img_dist="{{ dist }}" && \
    img_kas="{{ kas }}" && \
    img_sfx="{{ sfx }}" && \
    img_tag="${img_dist}-kas-${img_kas}${img_sfx}" && \
    {{ cli_exe }} run -it --rm \
      --mount "type=bind,source={{ repo_root }},target={{ cntr_repo_root }}" \
      --name "{{ cntr_name }}" \
      --workdir="{{ cntr_repo_root }}" \
      {{ cli_run_extra_opts }} \
      "{{ image_fqn }}:${img_tag}" \
      {{ cmd }}

run-clean:
    @if {{ cli_exe }} container inspect \
      -f '{{{{.State.Running}}' "{{ cntr_name }}" &>/dev/null; \
    then \
      {{ cli_exe }} rm --force "{{ cntr_name }}"; \
    fi

init: env-file

env-file:
    @[ -e "{{ repo_root }}/.env" ] || \
      install "{{ repo_root }}/.env.example" "{{ repo_root }}/.env"

env-file-clean:
    @rm -f "{{ repo_root }}/.env"

env-file-reset: env-file-clean env-file


git-tag dist=img_dist kas=img_kas sfx=img_sfx: init
    @. "{{ dotenv }}" && \
    img_dist="{{ dist }}" && \
    img_kas="{{ kas }}" && \
    img_sfx="{{ sfx }}" && \
    img_tag="${img_dist}-kas-${img_kas}${img_sfx}" && \
    git tag "${img_tag}"

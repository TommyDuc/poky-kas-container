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
# Override as follow: `$ just image_distro=my-distro-tag image`.
image_distro := "${DISTRO_CROPS_POKY:?}"
# Use the dotenv / env value by default.
# Override as follow: `$ just image_kas=my-kas-version image`.
image_kas := "${KAS_VERSION:?}"

default: image

clean: image-clean env-file-clean

reset: env-file-reset

login:
    @{{ cli_exe }} login "{{ registry_name }}"

logout:
    @{{ cli_exe }} logout "{{ registry_name }}"

image distro=image_distro kas=image_kas: init
    @. "{{ dotenv }}" && \
    DISTRO_CROPS_POKY="{{ distro }}" && \
    KAS_VERSION="{{ kas }}" && \
    image_tag="${DISTRO_CROPS_POKY}-kas-${KAS_VERSION}" && \
    {{ cli_exe }} build \
      --build-arg "DISTRO_CROPS_POKY=${DISTRO_CROPS_POKY}" \
      --build-arg "KAS_VERSION=${KAS_VERSION}" \
      --tag "{{ image_fqn }}:${image_tag}" \
      --file "Containerfile" \
      "{{ repo_root }}"

image-clean: run-clean
    @{{ cli_exe }} images -q --filter "reference={{ image_name }}" \
    | sort | uniq \
    | xargs --no-run-if-empty {{ cli_exe }} rmi -f

image-publish distro=image_distro kas=image_kas: (image distro kas)
    @. "{{ dotenv }}" && \
    DISTRO_CROPS_POKY="{{ distro }}" && \
    KAS_VERSION="{{ kas }}" && \
    image_tag="${DISTRO_CROPS_POKY}-kas-${KAS_VERSION}" && \
    {{ cli_exe }} push "{{ image_fqn }}:${image_tag}"

run cmd=cntr_cmd distro=image_distro kas=image_kas: (image distro kas)
    @. "{{ dotenv }}" && \
    DISTRO_CROPS_POKY="{{ distro }}" && \
    KAS_VERSION="{{ kas }}" && \
    image_tag="${DISTRO_CROPS_POKY}-kas-${KAS_VERSION}" && \
    {{ cli_exe }} run -it --rm \
      --mount "type=bind,source={{ repo_root }},target={{ cntr_repo_root }}" \
      --name "{{ cntr_name }}" \
      --workdir="{{ cntr_repo_root }}" \
      {{ cli_run_extra_opts }} \
      "{{ image_fqn }}:${image_tag}" \
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

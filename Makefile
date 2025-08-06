HERMETO := podman run --rm -ti -v "$$PWD:$$PWD:z" -w "$$PWD" quay.io/konflux-ci/hermeto:latest
generate-requirements: uv.lock
	uv pip compile pyproject.toml -o requirements-build.txt --generate-hashes --group build >/dev/null

uv.lock: pyproject.toml
	uv sync

hermetic-build: uv.lock generate-requirements
	$(HERMETO) fetch-deps \
		--source . \
		--output ./hermeto-output '{"type": "pip", "path": ".", "requirements_files": [], "allow_binary": false}'
	$(HERMETO) generate-env ./hermeto-output -o ./hermeto.env --for-output-dir /tmp/hermeto-output
	podman build . -f Containerfile.ubi9 \
		--volume "$(realpath ./hermeto-output)":/tmp/hermeto-output:Z \
		--volume "$(realpath ./hermeto.env)":/tmp/hermeto.env:Z \
		--network none


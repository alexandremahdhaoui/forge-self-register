# forge-self-register

The register instance for the forge toolchain: the catalog of adoptable
versions for forge, forge-ci, forge-factory, forge-register and the spec
repos. The pipeline is the only writer.

Every member enters the internal track by proof. The forge-self workspace
pipeline gates on the toolchain's own test suites, mints a revision that
pins every member's sha, and the publish stage writes each member into the
internal track with that revision as provenance. A consumer running
`forge run <module> <name>` resolves the proven tuple with no version
typed.

Operations, run in this checkout:

```sh
forge-register status
forge-register apply
forge-ci apply --config forge-self-register/forge-ci.yaml --root ..
```

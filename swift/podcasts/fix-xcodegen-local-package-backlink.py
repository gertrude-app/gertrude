from pathlib import Path
import re
import sys

if len(sys.argv) not in (4, 5):
    raise RuntimeError(
        "Usage: fix-xcodegen-local-package-backlink.py "
        "<project.pbxproj> <product-name> <generated-path> [corrected-path]"
    )

project_file = Path(sys.argv[1])
product_name = sys.argv[2]
generated_path = sys.argv[3]
corrected_path = sys.argv[4] if len(sys.argv) == 5 else generated_path
project = project_file.read_text()
original_project = project
candidate_paths = dict.fromkeys([generated_path, corrected_path])
references = []

for candidate_path in candidate_paths:
    pattern = re.compile(
        rf'^\s*([A-F0-9]+) /\* (XCLocalSwiftPackageReference "{re.escape(candidate_path)}") \*/ = \{{$',
        re.MULTILINE,
    )
    references.extend(pattern.findall(project))

if len(references) != 1:
    raise RuntimeError(f"Expected one matching local package reference, found {len(references)}")

reference_id, reference_name = references[0]
if generated_path != corrected_path:
    updated_reference_name = f'XCLocalSwiftPackageReference "{corrected_path}"'
    project = project.replace(reference_name, updated_reference_name)
    project, path_count = re.subn(
        rf'(\s*relativePath = "){re.escape(generated_path)}(";\n)',
        rf"\g<1>{corrected_path}\g<2>",
        project,
    )
    if path_count == 0:
        project, path_count = re.subn(
            rf'(\s*relativePath = "){re.escape(corrected_path)}(";\n)',
            rf"\g<1>{corrected_path}\g<2>",
            project,
        )
    if path_count != 1:
        raise RuntimeError(f"Expected one local package relative path, found {path_count}")
    reference_name = updated_reference_name

product_pattern = re.compile(
    rf"(?P<header>^\s*[A-F0-9]+ /\* {re.escape(product_name)} \*/ = \{{\n"
    r"\s*isa = XCSwiftPackageProductDependency;\n)"
    r"(?:\s*package = [^\n]+\n)?",
    re.MULTILINE,
)
replacement = rf"\g<header>\t\t\tpackage = {reference_id} /* {reference_name} */;\n"
project, replacement_count = product_pattern.subn(replacement, project)

if replacement_count != 1:
    raise RuntimeError(f"Expected one {product_name} product dependency, found {replacement_count}")

if project != original_project:
    project_file.write_text(project)

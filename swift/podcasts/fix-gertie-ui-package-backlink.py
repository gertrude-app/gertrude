from pathlib import Path
import re
import sys

project_file = Path(sys.argv[1])
project = project_file.read_text()
reference = re.search(
    r'^\s*([A-F0-9]+) /\* (XCLocalSwiftPackageReference "[^"]*gertie-ui") \*/ = \{$',
    project,
    re.MULTILINE,
)

if reference is None:
    raise RuntimeError("GertieUI local package reference was not found")

reference_id, reference_name = reference.groups()
if len(sys.argv) > 2:
    relative_path = sys.argv[2]
    updated_reference_name = f'XCLocalSwiftPackageReference "{relative_path}"'
    project = project.replace(reference_name, updated_reference_name)
    project, path_count = re.subn(
        r'(\s*relativePath = ")[^"]*gertie-ui(";\n)',
        rf"\g<1>{relative_path}\g<2>",
        project,
    )
    if path_count != 1:
        raise RuntimeError(f"Expected one GertieUI relative path, found {path_count}")
    reference_name = updated_reference_name

pattern = re.compile(
    r"(?P<header>^\s*[A-F0-9]+ /\* GertieUI \*/ = \{\n"
    r"\s*isa = XCSwiftPackageProductDependency;\n)"
    r"(?:\s*package = [^\n]+\n)?",
    re.MULTILINE,
)
replacement = rf"\g<header>\t\t\tpackage = {reference_id} /* {reference_name} */;\n"
project, replacement_count = pattern.subn(replacement, project)

if replacement_count != 1:
    raise RuntimeError(f"Expected one GertieUI product dependency, found {replacement_count}")

project_file.write_text(project)

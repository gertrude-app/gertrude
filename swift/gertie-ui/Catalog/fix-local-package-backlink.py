from pathlib import Path
import re

project_file = next(Path(".").glob("*.xcodeproj/project.pbxproj"))
project = project_file.read_text()
references = re.findall(
    r'^\s*([A-F0-9]+) /\* (XCLocalSwiftPackageReference "[^"]+") \*/ = \{$',
    project,
    re.MULTILINE,
)

if len(references) != 1:
    raise RuntimeError(f"Expected one local package reference, found {len(references)}")

reference_id, reference_name = references[0]
pattern = re.compile(
    r"(?P<header>^\s*[A-F0-9]+ /\* [^*]+ \*/ = \{\n"
    r"\s*isa = XCSwiftPackageProductDependency;\n)"
    r"(?!\s*package = )",
    re.MULTILINE,
)
replacement = rf'\g<header>\t\t\tpackage = {reference_id} /* {reference_name} */;\n'
project, replacement_count = pattern.subn(replacement, project)

if replacement_count == 0 and f"package = {reference_id}" not in project:
    raise RuntimeError("Local package product dependency was not found")

project_file.write_text(project)

from pathlib import Path
import re

project_file = Path("GertrudeMusic.xcodeproj/project.pbxproj")
project = project_file.read_text()
reference = re.search(
    r'^\s*([A-F0-9]+) /\* (XCLocalSwiftPackageReference "\.\./gertie-ui") \*/ = \{$',
    project,
    re.MULTILINE,
)

if reference is None:
    raise RuntimeError("GertieUI local package reference was not found")

reference_id, reference_name = reference.groups()
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

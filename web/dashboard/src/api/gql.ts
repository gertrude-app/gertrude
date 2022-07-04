export default function gql(
  strings: TemplateStringsArray,
  ...values: (string | number)[]
): string {
  let str = ``;
  strings.forEach((string, i) => {
    str += string + (values[i] || ``);
  });
  return str;
}

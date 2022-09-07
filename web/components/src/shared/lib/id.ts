export function isUnsaved(id: UUID): boolean {
  return id === `__client_generated_temp_id__`;
}

export function unsavedId(): UUID {
  return `__client_generated_temp_id__`;
}


-- KAN-99: Fotografías de perfil.
-- Crear bucket para las imágenes de los usuarios.

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'avatares',
  'avatares',
  true,
  5242880,
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
)
ON CONFLICT (id)
DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Permitir a cada usuario autenticado subir
-- fotografías únicamente dentro de su carpeta.

DROP POLICY IF EXISTS
  "avatares_subida_propia"
ON storage.objects;

CREATE POLICY "avatares_subida_propia"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatares'
  AND (storage.foldername(name))[1] =
      (SELECT auth.uid())::text
);

-- El bucket permite leer las imágenes mediante URL pública.
-- No se otorgan permisos adicionales para modificar
-- o eliminar fotografías ajenas.

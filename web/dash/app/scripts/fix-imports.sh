find dash/app/src \
  -path '**/__generated__/*.ts' \
  -exec sed -E -i "" "s/'[^t]+\/types\/src\/api/'\@dash\/types/g" {} +

FROM docker4gis/aspdotnet-builder:488 as builder

FROM docker4gis/aspdotnet:491

COPY --from=builder /app .

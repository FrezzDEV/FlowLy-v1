# FlowLy architecture

## Repository layout

```text
backend/
  src/
    app.js                 Express composition
    server.js              process entry point
    config/                environment configuration
    db/                    MongoDB connection
    models/                persistence models
    providers/             external media providers
    routes/                HTTP endpoints only
    services/              application/domain services

lib/
  app/                     composition root, theme, routing, bootstrap
  core/                    cross-cutting infrastructure
  data/                    API data sources, DTOs, repository implementations
  domain/                  repository contracts and domain models
  features/
    player/                playback infrastructure and player UI
    home/                  home feature
    search/                search feature
    library/               library feature
    profile/               profile feature
    downloads/             downloads feature
  shared/                  only truly reusable presentation primitives
```

## Dependency rules

- `app` composes dependencies; features do not construct global services themselves.
- `features` may depend on `domain`, `data` abstractions, and `core`; they should not import backend files.
- `data` implements `domain` contracts and owns JSON/network mapping.
- `domain` contains contracts and business models, without Flutter or HTTP details.
- The player consumes a resolved stream URL and media metadata. Search belongs to the music data/repository layer.
- Express routes validate/translate HTTP requests and delegate to services.
- Provider-specific code stays behind `backend/src/providers/`.
- Environment values are read in one place.

## Adding a feature

1. Add the feature under `lib/features/<name>/`.
2. Put API/local data access in `lib/data/` and expose it through a repository contract in `lib/domain/`.
3. Keep shared widgets generic; feature widgets stay inside the feature.
4. Add dependencies in `lib/app/` composition, not inside leaf widgets.

## Playback flow

`Home/Search -> MusicRepository -> MusicApi -> /api/search`

`Track -> MusicRepository -> /api/stream/:videoId -> AudioPlayerService -> just_audio -> audio_service`

$ErrorActionPreference = 'Stop'
cd 'C:\Projects\app-km\mobile'
flutter pub get
flutter run -d 138097055K002340 `
  --dart-define=AWS_REGION=us-east-1 `
  --dart-define=COGNITO_USER_POOL_ID=us-east-1_o7brV5nSd `
  --dart-define=COGNITO_USER_POOL_CLIENT_ID=1lv5nb6p133n9ct7stfgqc361s `
  --dart-define=COGNITO_IDENTITY_POOL_ID=us-east-1:e9ffa385-0a90-41f3-a24f-bece189db90b `
  --dart-define=IDENTITY_API_URL=https://ap-83e292773b1e4a86a3f1495622c25635.ecs.us-east-1.on.aws `
  --dart-define=ATHLETES_API_URL=https://ap-8e105e47346646be99cbb4ad3cfb77df.ecs.us-east-1.on.aws `
  --dart-define=STRAVA_AUTH_BACKEND_URL=https://ap-8e105e47346646be99cbb4ad3cfb77df.ecs.us-east-1.on.aws `
  --dart-define=STRAVA_REDIRECT_URI=https://ap-8e105e47346646be99cbb4ad3cfb77df.ecs.us-east-1.on.aws/api/v1/athletes/strava/callback

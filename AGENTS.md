# Agent Guide: CoreventApp

## Stack & Commands
- **Framework**: .NET MAUI (`net10.0-android`, `net10.0-windows10.0.19041.0`). `WindowsPackageType=None` (unpackaged) except Windows `Release` builds (MSIX).
- **Pattern**: MVVM via `CommunityToolkit.Mvvm 8.4.2` source generators (`[ObservableProperty]`, `[RelayCommand]`). `CommunityToolkit.Maui 13.0.0` for converters/behaviors/dialogs.
- **Build**: `dotnet build -f net10.0-windows10.0.19041.0 --no-restore` (Windows; `--no-restore` after first restore). Android build fails on this machine with XA0030/JDK — environmental, ignore it.
- **Run**: `dotnet run -f net10.0-windows10.0.19041.0` (Windows) or `dotnet build -t:Run -f net10.0-android` (Android).
- **Tests**: `dotnet test Tests/CoreventApp.UnitTests/CoreventApp.UnitTests.csproj` (xunit + Shouldly + Moq + RichardSzalay.MockHttp 7.0.0). ~248 tests, must stay green.
- **Shell is PowerShell**: `head`/`grep` don't exist — use `Select-Object -First/-Last`, `Select-String`. Never `cd` inside commands; use the `workdir` parameter. Line endings are LF (`.gitattributes`).
- **Font**: registered as `"Plus Jakarta Sans"` (with spaces) from `PlusJakartaSans-VariableFont_wght.ttf` in `MauiProgram.cs`; referenced as `FontFamily="Plus Jakarta Sans"` in `Resources/Styles/Styles.xaml`.
- **Icons**: `AathifMahir.Maui.MauiIcons.Cupertino` package, initialized via `.UseCupertinoMauiIcons()`.

## Critical Quirks
- **XAML Codegen**: `<MauiXamlInflator>SourceGen</MauiXamlInflator>` is enabled. Every new XAML file **MUST** be manually added to `CoreventApp.csproj` as `<MauiXaml Update="Views\X.xaml"><Generator>MSBuild:Compile</Generator></MauiXaml>` or `InitializeComponent()` fails.
- **DI Registration**: All Views and ViewModels **MUST** be registered in `MauiProgram.cs` (both as `Transient`). Singletons: `AppShell`, `TokenService`, `IAuthService`, `IDialogService`.
- **Partial Classes**: ViewModels and Code-behinds **MUST** be `partial` for source generators.
- **Commands**: `[RelayCommand]` on `DoSomethingAsync` generates `DoSomethingCommand` (strips `Async`).
- **Refit.Reflection is REQUIRED**: `Refit`, `Refit.HttpClientFactory`, `Refit.Reflection`, `Refit.Testing` (all 16.1.0) + `Microsoft.Extensions.Http` (10.0.12, aligned). The Refit source generator does not emit clients for this csproj's Windows TFM — without `Refit.Reflection` the app crashes at startup. Do not remove it.
- **EventToCommandBehavior needs explicit BindingContext** (toolkit v10+ breaking change — behaviors no longer inherit it; without this the command silently never fires):
  `<toolkit:EventToCommandBehavior EventName="Appearing" BindingContext="{Binding Source={x:Reference ThisPage}, Path=BindingContext}" Command="{Binding LoadCommand}" />`
  plus `x:Name="ThisPage"` on the page. Same rule applies to any behavior with a bound `Command`.
- **CompareConverter/IsEqualConverter do NO type coercion** (verified in toolkit source): `int` vs `ConverterParameter="1"` (string) is always false. Step wizards use per-step `CompareConverter` resources with `<x:Int32>` `ComparingValue`.
- **MockHttp v7 wildcards**: `*` works only at the END of the URL or as an exact full URL. `*` in the middle never matches. Prefer `Mock<I*Api>` in ViewModel tests; MockHttp only in `*ApiIntegrationTests`.
- **Scanning**: Uses `ZXing.Net.Maui` (`.UseBarcodeReader()`) + `QRCoder` for ticket QR generation.
- **JSON**: All API serialization uses `JsonConfig.Options` (camelCase, `UtcDateTimeConverter` in `Services/Api/JsonConfig.cs`).

## API (Refit)
- **Base URL**: hardcoded in `MauiProgram.cs` to `https://corevent-app-fatec-d78bb2efd71a.herokuapp.com/`. There is no dev/localhost URL — point at a local API by editing `MauiProgram.cs`.
- **Clients**: 17 `I*Api` interfaces in `Services/Api/` registered via `AddRefitClient` + `RefitConfig.CreateSettings()`:
  - `IAuthApi` — NO token handler (used by `AuthTokenHandler` itself to avoid recursion).
  - All other 16 get `.AddHttpMessageHandler<AuthTokenHandler>()` for auto Bearer token + refresh.
- **RefitConfig** (`Services/Api/RefitConfig.cs`): `SystemTextJsonContentSerializer` + `UtcDateTimeConverter` + `CoreventUrlFormatter` (bools as lowercase, `DateTime` query params as `yyyy-MM-dd`).
- **Errors**: Refit throws `ApiException`; `ApiResult.TryExecuteAsync` bridges to the `null`/`false`/empty-page contract — call sites must handle the null case, failures are silent by design (only `Debug.WriteLine`).
- **Kept orchestration services** (do NOT inline into VMs): `AuthService` (stateful, `_cachedUser`), `FavoritesService` (`ConcurrentDictionary` cache shared across VMs), `PaymentInfoService` (list + N×`GetById` fan-out), `StorageService` (presign → PUT via `StorageUploadHelper` → confirm).
- **AuthTokenHandler** (`DelegatingHandler`): Injects `Authorization: Bearer`. On 401, refreshes via named client `"auth-refresh"` (`POST /api/auth/refresh`), saves tokens, retries once. On refresh failure, clears tokens.

## Auth Flow
- **Storage**: `SecureStorage` keys `access_token` / `refresh_token` (`TokenService`). User data cached in-memory (`_cachedUser` in `AuthService`).
- **Startup**: `App.xaml.cs` opens a raw `LoadingPage` window, calls `AuthService.GetCurrentUserAsync()` (refresh token + fetch profile), then swaps `window.Page = appShell`. Authenticated → `//main`; else stay on `//welcome`.
- **Login**: `POST /api/auth/login` → save tokens → `GET /api/users/me` → cache user.
- **Register**: `POST /api/auth/verify-email` (sends code) → user enters code → `POST /api/auth/register` → auto-login.
- **Forgot Password**: `POST /api/auth/forgot-password` → code entry → `POST /api/auth/reset-password`.
- **Logout**: `POST /api/auth/logout` → clear tokens.

## UI Conventions
- **Never call `Shell.Current.DisplayAlertAsync` from VMs** — inject `IDialogService` (`ShowErrorAsync` / `ShowAlertAsync` / `ConfirmAsync` / `ShowToastAsync`). It no-ops without a UI context, so unit tests stay green (pass `new DialogService()` in tests).
- **Validation that shows dialogs must be `async`**: sync `bool Validate*()` + fire-and-forget alerts is banned — use `Task<bool> Validate*Async()` and `await` it (see `RegisterViewModel`, `CreateEventViewModel`).
- **Page-load pattern**: `EventToCommandBehavior` on `Appearing` (with explicit BindingContext, see Quirks). Keep code-behind `OnAppearing` only for conditional loads (`PurchaseHistory`: load-if-empty) and event subscribe/unsubscribe (`CheckInPage` camera).
- **Converters**: generic ones come from the toolkit (`InvertedBoolConverter`, `IsStringNotNullOrEmptyConverter`, `CompareConverter` — global keys live in `App.xaml`). `Converters/` keeps ONLY domain mappings: `CategoryDisplayConverter`, `LocationTypeDisplayConverter`, `StatusDisplayConverter`, `RatingToStarsConverter`.
- **Live validation**: `EmailValidationBehavior` (+ `InvalidEntryStyle`) on email entries instead of submit-time alerts only.

## Navigation & Deep Links
- **TabBar** route is `//main` (tabs: `home`, `explore`, `tickets`, `profile`). `welcome` is a top-level `ShellContent` outside the TabBar. Detail pages are registered via `Routing.RegisterRoute` in `AppShell.xaml.cs` (route name = page class name; see Routes list below).
- **Deep links** (`corevent://` scheme, handled in `App.xaml.cs`): `corevent://orders` → `//main/tickets`; `corevent://invites` → `UserInvitations`. Deep links only work on Windows when packaged/installed as MSIX (see README for cert + `dotnet publish` steps) — `dotnet run` does not register the protocol.

## Routes
Detail pages (pushed via Shell navigation). Route name = page class name:
`Login`, `Register`, `UpdatePassword`, `Privacy`, `EditProfile`, `PurchaseHistory`, `Favorites`, `Reviews`, `Settings`, `PanelOrganizer`, `TransferSettings`, `AddBankAccount`, `AddPixKey`, `PanelCollaborator`, `CreateEvent`, `ManageEvent`, `ParticipantList`, `EventTeam`, `CheckInPage`, `EventAttractions`, `CollaboratorEventDetail`, `EventDetail`, `ManageTicketsPage`, `CheckoutPage`, `EmailVerification`, `ForgotPassword`, `ResetPassword`, `UserInvitations`, `TicketQrCodePage`, `OrderDetailPage`.

Each `Views/Page.xaml` has a matching `ViewModels/PageViewModel.cs` (e.g. `CheckInPage` → `CheckInViewModel`, `ManageTicketsPage` → `ManageTicketsViewModel`).

## Workflow: New Page
1. Create `Views/Page.xaml`, `Views/Page.xaml.cs` (`BindingContext = viewModel` in ctor), and `ViewModels/PageViewModel.cs` (inject `IDialogService` if it shows any dialog).
2. Add `<MauiXaml Update="Views\Page.xaml"><Generator>MSBuild:Compile</Generator></MauiXaml>` to `CoreventApp.csproj`.
3. Register View + ViewModel as `Transient` in `MauiProgram.cs`.
4. Register route in `AppShell.xaml.cs` (detail) or add to `TabBar` in `AppShell.xaml` (main tabs).
5. For Appearing loads use `EventToCommandBehavior` with explicit BindingContext (see Quirks); add `x:DataType` compiled bindings.

## Debugging a Startup Crash
- `dotnet build -t:Run` failing with `MSB3073 ... exited with code -1073741189` means the app **built fine but crashed at startup**. `-1073741189` = `0xC000027B` (`STATUS_STOWED_EXCEPTION`): an unhandled managed exception on the UI thread, surfaced with no message.
- Get the real stack trace from **Event Viewer → Windows Logs → Application → `.NET Runtime` entry** for `CoreventApp.exe` (the `Application Error` entry only shows the native faulting module, usually `Microsoft.UI.Xaml.dll`).
- Suspects in order: DI resolve failure in `App` ctor (unregistered service, Refit proxy creation), throw in `CreateWindow`/`InitializeAsync`, XAML parse error on first page.

## Resources
- Colors: Use keys from `Resources/Styles/Colors.xaml` (e.g., `primary_orange_color`).

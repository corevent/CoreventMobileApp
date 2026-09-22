using System.Collections.ObjectModel;
using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Models.Dtos;
using CoreventApp.Services;
using CoreventApp.Services.Api;
using CoreventApp.Views;

namespace CoreventApp.ViewModels;

[QueryProperty(nameof(EditingEventId), "EventId")]
public partial class CreateEventViewModel : ObservableObject
{
    private const int TotalSteps = 3;
    private readonly IEventsApi _eventsApi;
    private readonly IStatesApi _statesApi;
    private readonly PaymentInfoService _paymentInfoService;
    private readonly StorageService _storageService;
    private readonly IDialogService _dialogs;
    private string? _editingEventId;
    private EventDetailDto? _originalEvent;

    [ObservableProperty]
    public partial int CurrentStep { get; set; } = 1;

    [ObservableProperty]
    public partial double Progress { get; set; } = 0.33;

    [ObservableProperty]
    public partial string PageTitle { get; set; } = "Criar Evento";

    [ObservableProperty]
    public partial string StepTitle { get; set; } = "Informações Básicas";

    [ObservableProperty]
    public partial string StepDescription { get; set; } = "Conte os detalhes principais do seu evento.";

    [ObservableProperty]
    public partial string ButtonNextText { get; set; } = "Próximo";

    [ObservableProperty]
    public partial CreateEventRequest Form { get; set; } = new();

    [ObservableProperty]
    public partial bool IsEditing { get; set; }

    [ObservableProperty]
    public partial bool IsEditable { get; set; } = true;

    [ObservableProperty]
    public partial bool ShowDraftButton { get; set; } = true;

    [ObservableProperty]
    public partial bool ShowPublishButton { get; set; } = true;

    [ObservableProperty]
    public partial string DraftButtonText { get; set; } = "Salvar Rascunho";

    [ObservableProperty]
    public partial bool IsLoadingStates { get; set; }

    [ObservableProperty]
    public partial bool IsSaving { get; set; }

    [ObservableProperty]
    public partial bool IsUploadingBanner { get; set; }

    public DateTime Today => DateTime.Today;
    public DateTime Tomorrow => DateTime.Today.AddDays(1);

    public DateTime StartDateMinimum => IsEditing ? Form.StartDate.AddDays(-1) : Tomorrow;

    public List<string> Categories { get; } = new()
    {
        "Música", "Esportes", "Tecnologia", "Negócios", "Educação",
        "Arte e Cultura", "Gastronomia", "Saúde e Bem-estar",
        "Família e Crianças", "Religioso/Espiritual", "Jogos",
        "Comunidade/Social", "Moda e Beleza", "Outro"
    };

    public ObservableCollection<string> LocationTypes { get; } = new()
    {
        "Online", "Presencial", "Híbrido"
    };

    private static readonly Dictionary<string, string> CategoryToApi = new()
    {
        ["Música"] = "music",
        ["Esportes"] = "sports",
        ["Tecnologia"] = "tech",
        ["Negócios"] = "business",
        ["Educação"] = "education",
        ["Arte e Cultura"] = "art_culture",
        ["Gastronomia"] = "gastronomy",
        ["Saúde e Bem-estar"] = "health_wellness",
        ["Família e Crianças"] = "family_kids",
        ["Religioso/Espiritual"] = "religious_spiritual",
        ["Jogos"] = "games",
        ["Comunidade/Social"] = "community_social",
        ["Moda e Beleza"] = "fashion_beauty",
        ["Outro"] = "other"
    };

    private FileResult? _bannerFile;

    private static readonly Dictionary<string, string> LocationTypeToApi = new()
    {
        ["Online"] = "online",
        ["Presencial"] = "in_person",
        ["Híbrido"] = "hybrid"
    };

    public CreateEventViewModel(IEventsApi eventsApi, IStatesApi statesApi, PaymentInfoService paymentInfoService, StorageService storageService, IDialogService dialogService)
    {
        _eventsApi = eventsApi;
        _statesApi = statesApi;
        _paymentInfoService = paymentInfoService;
        _storageService = storageService;
        _dialogs = dialogService;
    }

    public string? EditingEventId
    {
        set
        {
            if (value is null) return;
            _editingEventId = value;
            _ = LoadEditingEventAsync(value);
        }
    }

    private async Task LoadEditingEventAsync(string eventId)
    {
        var evt = (await ApiResult.TryExecuteAsync(() => _eventsApi.GetByIdAsync(eventId), "Load event"))?.Data;
        if (evt is null) return;

        _originalEvent = evt;
        IsEditing = true;
        Form.IsEditingForm = true;

        Form.Title = evt.Title;
        Form.Description = evt.Description ?? string.Empty;
        Form.MaxParticipants = evt.MaxParticipants;
        Form.StartDate = evt.StartDate;
        Form.EndDate = evt.EndDate;
        Form.IsOver18 = evt.IsAdultOnly;
        Form.ZipCode = evt.ZipCode ?? string.Empty;
        Form.Neighborhood = evt.Neighborhood ?? string.Empty;
        Form.Street = evt.Street ?? string.Empty;
        Form.Number = evt.Number?.ToString() ?? "0";
        Form.Complement = evt.Complement ?? string.Empty;
        Form.LocationName = evt.LocationName;
        Form.BannerUrl = evt.BannerUrl ?? string.Empty;

        var locationTypeDisplay = LocationTypeToApi
            .FirstOrDefault(x => x.Value == evt.LocationType).Key;
        if (locationTypeDisplay is not null)
            Form.LocationType = locationTypeDisplay;

        var categoryDisplay = CategoryToApi
            .FirstOrDefault(x => x.Value == evt.Category).Key;
        if (categoryDisplay is not null)
            Form.Category = categoryDisplay;

        UpdateLocationTypesForEditing();

        // Determine editability
        var now = DateTime.UtcNow;
        IsEditable = evt.Status switch
        {
            "draft" => true,
            "opened" => now <= evt.StartDate,
            "going" => false,
            "finished" => false,
            "canceled" => false,
            _ => true
        };

        bool isOpened = evt.Status == "opened";
        ShowPublishButton = IsEditable && !isOpened;
        ShowDraftButton = IsEditable;
        DraftButtonText = isOpened ? "Salvar Alterações" : "Salvar Rascunho";

        UpdateUI();

        // Load states and pre-select
        if (evt.CityId > 0)
        {
            await LoadStatesAsync();
            var matchedState = Form.States.FirstOrDefault(s => s.Uf == evt.StateAcronym);
            var stateIdx = matchedState is not null ? Form.States.IndexOf(matchedState) : -1;
            if (stateIdx >= 0)
                Form.SelectedStateIndex = stateIdx;
        }
    }

    private void UpdateLocationTypesForEditing()
    {
        LocationTypes.Clear();
        if (_originalEvent?.LocationType is not null &&
            _originalEvent.LocationType != "online")
        {
            LocationTypes.Add("Presencial");
            LocationTypes.Add("Híbrido");
            if (Form.LocationType == "Online")
                Form.LocationType = "Presencial";
        }
        else
        {
            LocationTypes.Add("Online");
            LocationTypes.Add("Presencial");
            LocationTypes.Add("Híbrido");
        }
    }

    [RelayCommand]
    private async Task LoadStatesAsync()
    {
        try
        {
            IsLoadingStates = true;
            var response = await ApiResult.TryExecuteAsync(() => _statesApi.GetStatesAsync(), "Load states");
            if (response is null)
            {
                Debug.WriteLine("Load states failed: no response");
                await _dialogs.ShowErrorAsync("Não foi possível carregar a lista de estados.");
                return;
            }
            Form.States.Clear();
            foreach (var s in response.Data)
                Form.States.Add(s);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Load states failed: {ex.Message}");
            await _dialogs.ShowErrorAsync("Não foi possível carregar a lista de estados.");
        }
        finally
        {
            IsLoadingStates = false;
        }
    }

    [RelayCommand]
    private async Task LoadCitiesAsync()
    {
        var state = Form.SelectedState;
        if (state is null) return;

        try
        {
            IsLoadingStates = true;
            var response = await ApiResult.TryExecuteAsync(() => _statesApi.GetCitiesAsync(state.Id), "Load cities");
            if (response is null)
            {
                Debug.WriteLine("Load cities failed: no response");
                await _dialogs.ShowErrorAsync("Não foi possível carregar a lista de cidades.");
                return;
            }
            Form.Cities.Clear();
            foreach (var c in response.Data)
                Form.Cities.Add(c);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Load cities failed: {ex.Message}");
            await _dialogs.ShowErrorAsync("Não foi possível carregar a lista de cidades.");
        }
        finally
        {
            IsLoadingStates = false;
        }
    }

    [RelayCommand]
    private async Task NextAsync()
    {
        if (CurrentStep >= TotalSteps) return;

        if (!await ValidateStepAsync(CurrentStep)) return;

        CurrentStep++;
        UpdateUI();

        if (CurrentStep == 3 && Form.States.Count == 0)
            await LoadStatesAsync();
    }

    [RelayCommand]
    private async Task PickBanner()
    {
        try
        {
            var file = await FilePicker.Default.PickAsync(new PickOptions
            {
                PickerTitle = "Selecionar banner do evento",
                FileTypes = new FilePickerFileType(new Dictionary<DevicePlatform, IEnumerable<string>>
                {
                    { DevicePlatform.Android, new[] { "image/jpeg", "image/png", "image/webp" } },
                    { DevicePlatform.WinUI, new[] { ".jpg", ".jpeg", ".png", ".webp" } },
                })
            });

            if (file is null) return;

            var contentType = file.ContentType?.ToLowerInvariant() ?? string.Empty;
            if (contentType != "image/jpeg" && contentType != "image/png" && contentType != "image/webp" && contentType != "image/jpg")
            {
                await _dialogs.ShowAlertAsync("Formato inválido", "Selecione uma imagem nos formatos JPEG, PNG ou WebP.");
                return;
            }

            _bannerFile = file;
            Form.BannerPreview = file.FullPath;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"PickBanner failed: {ex.Message}");
        }
    }

    [RelayCommand]
    private async Task SaveDraftAsync()
    {
        if (!await ValidateAllAsync()) return;

        bool isOpened = _originalEvent?.Status == "opened";
        string targetStatus = isOpened ? "opened" : "draft";

        IsSaving = true;
        try
        {
            if (IsEditing && _editingEventId is not null)
            {
                var payload = BuildUpdatePayload(targetStatus);
                var result = (await ApiResult.TryExecuteAsync(() => _eventsApi.UpdatePartialAsync(_editingEventId, payload), "Save event"))?.Data;
                if (result is null)
                {
                    await _dialogs.ShowErrorAsync("Não foi possível salvar as alterações.");
                    return;
                }
                await UploadBannerIfNeeded(_editingEventId);
                var detail = isOpened ? "Suas alterações foram salvas com sucesso." : "As alterações foram salvas como rascunho.";
                await _dialogs.ShowToastAsync(detail);
            }
            else
            {
                var dto = BuildCreateDto(targetStatus, forUpdate: IsEditing);
                var result = (await ApiResult.TryExecuteAsync(() => _eventsApi.CreateAsync(dto), "Save event"))?.Data;
                if (result is null)
                {
                    await _dialogs.ShowErrorAsync("Não foi possível salvar o rascunho.");
                    return;
                }
                await UploadBannerIfNeeded(result.Id);
                await _dialogs.ShowToastAsync("Seu evento foi salvo como rascunho.");
            }

            await Shell.Current.GoToAsync("../..");
        }
        finally
        {
            IsSaving = false;
        }
    }

    [RelayCommand]
    private async Task PublishEventAsync()
    {
        if (!await ValidateAllAsync()) return;

        if (_originalEvent?.Status == "opened")
        {
            await _dialogs.ShowAlertAsync("Já Publicado",
                "Este evento já está publicado. Use 'Salvar Alterações' para editar os dados.");
            return;
        }

        // Check if organizer has payment info registered
        var paymentInfos = await _paymentInfoService.GetAllAsync();
        if (paymentInfos.Count == 0)
        {
            var goToConfig = await _dialogs.ConfirmAsync(
                "Dados de Repasse Necessários",
                "Você precisa cadastrar seus dados de repasse antes de publicar um evento. Deseja configurar agora?",
                "Configurar Agora", "Cancelar");
            if (goToConfig)
                await Shell.Current.GoToAsync(nameof(Views.TransferSettings));
            return;
        }

        IsSaving = true;
        try
        {
            if (IsEditing && _editingEventId is not null)
            {
                var payload = BuildUpdatePayload("opened");
                var result = (await ApiResult.TryExecuteAsync(() => _eventsApi.UpdatePartialAsync(_editingEventId, payload), "Save event"))?.Data;
                if (result is null)
                {
                    await _dialogs.ShowErrorAsync("Não foi possível publicar o evento.");
                    return;
                }
                await UploadBannerIfNeeded(_editingEventId);
                await _dialogs.ShowToastAsync("Suas alterações foram publicadas.");
            }
            else
            {
                var dto = BuildCreateDto("opened", forUpdate: IsEditing);
                var result = (await ApiResult.TryExecuteAsync(() => _eventsApi.CreateAsync(dto), "Save event"))?.Data;
                if (result is null)
                {
                    await _dialogs.ShowErrorAsync("Não foi possível publicar o evento.");
                    return;
                }
                await UploadBannerIfNeeded(result.Id);
                await _dialogs.ShowToastAsync("Seu evento foi publicado com sucesso!");
            }

            await Shell.Current.GoToAsync("../..");
        }
        finally
        {
            IsSaving = false;
        }
    }

    [RelayCommand]
    private async Task BackAsync()
    {
        if (CurrentStep > 1)
        {
            CurrentStep--;
            UpdateUI();
            return;
        }

        await Shell.Current.GoToAsync("..");
    }

    private async Task<bool> ValidateStepAsync(int step)
    {
        return step switch
        {
            1 => await ValidateStep1Async(),
            2 => Form.StartDate != default &&
                 (IsEditing || Form.StartDate > DateTime.Now) &&
                 Form.EndDate >= Form.StartDate,
            _ => true
        };
    }

    private async Task<bool> ValidateStep1Async()
    {
        if (string.IsNullOrWhiteSpace(Form.Title) || Form.Title.Trim().Length < 3)
        {
            await _dialogs.ShowErrorAsync("O título deve ter pelo menos 3 caracteres.");
            return false;
        }
        if (Form.Title.Trim().Length > 200)
        {
            await _dialogs.ShowErrorAsync("O título deve ter no máximo 200 caracteres.");
            return false;
        }
        if (Form.Description?.Length > 2000)
        {
            await _dialogs.ShowErrorAsync("A descrição deve ter no máximo 2000 caracteres.");
            return false;
        }
        return true;
    }

    private async Task<bool> ValidateAllAsync()
    {
        var valid = await ValidateStep1Async();

        valid = valid &&
            Form.StartDate != default &&
            Form.EndDate != default &&
            Form.EndDate >= Form.StartDate;

        if (!IsEditing && Form.StartDate <= DateTime.Now)
            valid = false;

        if (Form.MaxParticipants < 1)
        {
            await _dialogs.ShowErrorAsync("O número máximo de participantes deve ser pelo menos 1.");
            return false;
        }

        if (string.IsNullOrWhiteSpace(Form.Category))
        {
            await _dialogs.ShowErrorAsync("Selecione uma categoria para o evento.");
            return false;
        }

        if (Form.LocationType != "Online")
        {
            valid = valid &&
                !string.IsNullOrWhiteSpace(Form.Street) &&
                Form.Number.Length > 0 && int.TryParse(Form.Number, out int num) && num > 0 &&
                !string.IsNullOrWhiteSpace(Form.Neighborhood) &&
                !string.IsNullOrWhiteSpace(Form.ZipCode) && Form.ZipCode.Trim().Length == 8 && Form.ZipCode.All(char.IsDigit) &&
                Form.SelectedCityId > 0;

            if (!valid)
            {
                await _dialogs.ShowErrorAsync("Preencha todos os campos de endereço corretamente.");
                return false;
            }
        }

        return valid;
    }

    private CreateEventDto BuildCreateDto(string status, bool forUpdate = false)
    {
        var title = Form.Title.Trim();
        var category = CategoryToApi.GetValueOrDefault(Form.Category, "other");
        var locationType = LocationTypeToApi.GetValueOrDefault(Form.LocationType, "in_person");
        var isOnline = locationType == "online";

        int number = 0;
        int.TryParse(Form.Number, out number);

        return new CreateEventDto(
            Title: title,
            Description: Form.Description ?? string.Empty,
            MaxParticipants: Form.MaxParticipants,
            LocationType: locationType,
            LocationName: isOnline ? null : (Form.LocationName ?? string.Empty),
            CityId: isOnline ? null : Form.SelectedCityId,
            ZipCode: isOnline ? null : (Form.ZipCode ?? string.Empty),
            Neighborhood: isOnline ? null : (Form.Neighborhood ?? string.Empty),
            Street: isOnline ? null : (Form.Street ?? string.Empty),
            Number: isOnline ? null : number,
            Complement: string.IsNullOrWhiteSpace(Form.Complement) ? null : Form.Complement,
            StartDate: Form.StartDate,
            EndDate: Form.EndDate,
            Category: category,
            IsAdultOnly: Form.IsOver18,
            Status: status);
    }

    private Dictionary<string, object?> BuildUpdatePayload(string? status)
    {
        var payload = new Dictionary<string, object?>();
        var o = _originalEvent;
        if (o is null) return payload;

        var title = Form.Title.Trim();
        if (title != o.Title)
            payload["title"] = title;

        if (Changed(Form.Description, o.Description, out var descVal))
            payload["description"] = descVal;

        if (Form.MaxParticipants != o.MaxParticipants)
            payload["maxParticipants"] = Form.MaxParticipants;

        var locationType = LocationTypeToApi.GetValueOrDefault(Form.LocationType, "in_person");
        if (locationType != o.LocationType)
            payload["locationType"] = locationType;

        bool isOnline = locationType == "online";

        if (isOnline)
        {
            if (locationType != o.LocationType)
            {
                payload["locationName"] = null;
                payload["cityId"] = null;
                payload["zipCode"] = null;
                payload["neighborhood"] = null;
                payload["street"] = null;
                payload["number"] = null;
            }
        }
        else
        {
            if (Changed(Form.LocationName, o.LocationName, out var locNameVal))
                payload["locationName"] = locNameVal;

            var cityId = Form.SelectedCityId;
            if (cityId != (o.CityId ?? 0))
                payload["cityId"] = cityId > 0 ? cityId : null;

            if (Changed(Form.ZipCode, o.ZipCode, out var zipVal))
                payload["zipCode"] = zipVal;

            if (Changed(Form.Neighborhood, o.Neighborhood, out var neighVal))
                payload["neighborhood"] = neighVal;

            if (Changed(Form.Street, o.Street, out var streetVal))
                payload["street"] = streetVal;

            int number = 0;
            int.TryParse(Form.Number, out number);
            if (number != (o.Number ?? 0))
                payload["number"] = number > 0 ? number : null;
        }

        if (Changed(Form.Complement, o.Complement, out var compVal))
            payload["complement"] = compVal;

        if (Form.StartDate != o.StartDate)
            payload["startDate"] = Form.StartDate;

        if (Form.EndDate != o.EndDate)
            payload["endDate"] = Form.EndDate;

        var category = CategoryToApi.GetValueOrDefault(Form.Category, "other");
        if (category != o.Category)
            payload["category"] = category;

        if (Form.IsOver18 != o.IsAdultOnly)
            payload["isAdultOnly"] = Form.IsOver18;

        if (status is not null && status != o.Status)
            payload["status"] = status;

        return payload;
    }

    private static bool Changed(string? formValue, string? originalValue, out string? valueToSend)
    {
        var form = formValue ?? string.Empty;
        var orig = originalValue ?? string.Empty;
        if (form == orig)
        {
            valueToSend = null;
            return false;
        }
        valueToSend = string.IsNullOrWhiteSpace(form) ? null : form;
        return true;
    }

    private void UpdateUI()
    {
        Progress = (double)CurrentStep / TotalSteps;
        PageTitle = IsEditing ? "Editar Evento" : "Criar Evento";

        ButtonNextText = CurrentStep == TotalSteps ? (IsEditing ? "Salvar" : "Criar Evento") : "Próximo";

        StepTitle = CurrentStep switch
        {
            1 => "Informações Básicas",
            2 => "Data e Participação",
            3 => "Localização",
            _ => string.Empty
        };

        StepDescription = CurrentStep switch
        {
            1 => "Conte os detalhes principais do seu evento.",
            2 => "Defina quando será e quantos participantes poderão participar.",
            3 => "Onde o evento vai acontecer?",
            _ => string.Empty
        };
    }

    private async Task UploadBannerIfNeeded(string eventId)
    {
        if (_bannerFile is null) return;

        try
        {
            IsUploadingBanner = true;
            var contentType = _bannerFile.ContentType ?? "image/jpeg";
            await using var stream = await _bannerFile.OpenReadAsync();
            var publicUrl = await _storageService.UploadEventBannerAsync(eventId, stream, contentType);
            if (publicUrl is not null)
                Form.BannerUrl = publicUrl;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Banner upload failed: {ex.Message}");
        }
        finally
        {
            _bannerFile = null;
            IsUploadingBanner = false;
        }
    }
}

public partial class CreateEventRequest : ObservableObject
{
    [ObservableProperty]
    public partial string Id { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Title { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Description { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Category { get; set; } = string.Empty;

    [ObservableProperty]
    public partial bool IsOver18 { get; set; }

    [ObservableProperty]
    public partial DateTime StartDate { get; set; } = DateTime.Today.AddDays(30);

    [ObservableProperty]
    public partial DateTime EndDate { get; set; } = DateTime.Today.AddDays(31);

    [ObservableProperty]
    public partial bool IsEditingForm { get; set; }

    [ObservableProperty]
    public partial int MaxParticipants { get; set; } = 100;

    [ObservableProperty]
    public partial string LocationType { get; set; } = "Presencial";

    [ObservableProperty]
    public partial string LocationName { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string BannerUrl { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string BannerPreview { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string ZipCode { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Neighborhood { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Street { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Number { get; set; } = string.Empty;

    [ObservableProperty]
    public partial string Complement { get; set; } = string.Empty;

    // State / City cascading pickers
    public ObservableCollection<StateDataDto> States { get; } = new();
    public ObservableCollection<CityDataDto> Cities { get; } = new();

    [ObservableProperty]
    public partial int SelectedStateIndex { get; set; } = -1;

    [ObservableProperty]
    public partial int SelectedCityIndex { get; set; } = -1;

    public StateDataDto? SelectedState =>
        SelectedStateIndex >= 0 && SelectedStateIndex < States.Count
            ? States[SelectedStateIndex]
            : null;

    public int SelectedCityId
    {
        get
        {
            if (SelectedCityIndex >= 0 && SelectedCityIndex < Cities.Count)
                return Cities[SelectedCityIndex].Id;
            return 0;
        }
    }

    partial void OnSelectedStateIndexChanged(int value)
    {
        OnPropertyChanged(nameof(SelectedState));
        OnPropertyChanged(nameof(AddressError));
    }

    partial void OnSelectedCityIndexChanged(int value)
    {
        OnPropertyChanged(nameof(SelectedCityId));
        OnPropertyChanged(nameof(AddressError));
    }

    partial void OnLocationTypeChanged(string value)
    {
        OnPropertyChanged(nameof(IsPhysicalLocationVisible));
        OnPropertyChanged(nameof(TitleError));
        OnPropertyChanged(nameof(StartDateError));
        OnPropertyChanged(nameof(EndDateError));
        OnPropertyChanged(nameof(AddressError));
    }

    public bool IsPhysicalLocationVisible => LocationType != "Online";

    public string? TitleError => string.IsNullOrWhiteSpace(Title) ? "O título é obrigatório." : null;

    public string? StartDateError
    {
        get
        {
            if (StartDate == default) return "A data de início é obrigatória.";
            if (!IsEditingForm && StartDate <= DateTime.Now) return "A data de início deve ser no futuro.";
            return null;
        }
    }

    partial void OnIsEditingFormChanged(bool value) => OnPropertyChanged(nameof(StartDateError));

    public string? EndDateError
    {
        get
        {
            if (EndDate == default) return "A data de término é obrigatória.";
            if (EndDate < StartDate) return "A data de término não pode ser anterior à data de início.";
            return null;
        }
    }

    public string? AddressError
    {
        get
        {
            if (LocationType == "Online") return null;
            if (string.IsNullOrWhiteSpace(Street)) return "A rua é obrigatória.";
            if (string.IsNullOrWhiteSpace(Number) || !int.TryParse(Number, out int n) || n <= 0)
                return "Informe um número válido.";
            if (string.IsNullOrWhiteSpace(Neighborhood)) return "O bairro é obrigatório.";
            if (string.IsNullOrWhiteSpace(ZipCode)) return "O CEP é obrigatório.";
            if (SelectedCityId <= 0) return "Selecione uma cidade.";
            return null;
        }
    }

    partial void OnTitleChanged(string value) => OnPropertyChanged(nameof(TitleError));
    partial void OnStartDateChanged(DateTime value) { OnPropertyChanged(nameof(StartDateError)); OnPropertyChanged(nameof(EndDateError)); }
    partial void OnEndDateChanged(DateTime value) => OnPropertyChanged(nameof(EndDateError));
    partial void OnStreetChanged(string value) => OnPropertyChanged(nameof(AddressError));
    partial void OnNumberChanged(string value) => OnPropertyChanged(nameof(AddressError));
    partial void OnNeighborhoodChanged(string value) => OnPropertyChanged(nameof(AddressError));
    partial void OnZipCodeChanged(string value) => OnPropertyChanged(nameof(AddressError));
}

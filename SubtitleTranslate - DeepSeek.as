/*
    Real-time subtitle translation for PotPlayer using DeepSeek API
*/

// Plugin Information Functions
string GetTitle() {
    return "{$CP949=DeepSeek 번역$}{$CP950=DeepSeek 翻譯$}{$CP0=DeepSeek Translate$}";
}

string GetVersion() {
    return "2.0";
}

string GetDesc() {
    return "{$CP949=DeepSeek를 사용한 실시간 자막 번역$}{$CP950=使用 DeepSeek 的實時字幕翻譯$}{$CP0=Real-time subtitle translation using DeepSeek$}";
}

string GetLoginTitle() {
    return "{$CP949=DeepSeek 모델 및 API 키 구성$}{$CP950=DeepSeek 模型與 API 金鑰配置$}{$CP0=DeepSeek Model + API URL and API Key Configuration$}";
}

string GetLoginDesc() {
    return "{$CP949=모델 이름과 API 주소, 그리고 API 키를 입력하십시오 (예: deepseek-chat|https://api.deepseek.com/v1/chat/completions).$}{$CP950=請輸入模型名稱與 API 地址，以及 API 金鑰（例如 deepseek-chat|https://api.deepseek.com/v1/chat/completions）。$}{$CP0=Please enter the model name + API URL and provide the API Key (e.g., deepseek-chat|https://api.deepseek.com/v1/chat/completions).$}";
}

string GetUserText() {
    return "{$CP949=모델 이름|API 주소 (현재: " + selected_model + " | " + apiUrl + ")$}{$CP950=模型名稱|API 地址 (目前: " + selected_model + " | " + apiUrl + ")$}{$CP0=Model Name|API URL (Current: " + selected_model + " | " + apiUrl + ")$}";
}

string GetPasswordText() {
    return "{$CP949=API 키:$}{$CP950=API 金鑰:$}{$CP0=API Key:$}";
}

// Global Variables
string api_key = "";
string selected_model = "deepseek-chat"; // Default model
string apiUrl = "https://api.deepseek.com/v1/chat/completions"; // DeepSeek API URL
string UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)";

// Supported Language List
array<string> LangTable =
{
    "{$CP0=Auto Detect$}", "af", "sq", "am", "ar", "hy", "az", "eu", "be", "bn", "bs", "bg", "ca",
    "ceb", "ny", "zh-CN",
    "zh-TW", "co", "hr", "cs", "da", "nl", "en", "eo", "et", "tl", "fi", "fr",
    "fy", "gl", "ka", "de", "el", "gu", "ht", "ha", "haw", "he", "hi", "hmn", "hu", "is", "ig", "id", "ga", "it", "ja", "jw", "kn", "kk", "km",
    "ko", "ku", "ky", "lo", "la", "lv", "lt", "lb", "mk", "ms", "mg", "ml", "mt", "mi", "mr", "mn", "my", "ne", "no", "ps", "fa", "pl", "pt",
    "pa", "ro", "ru", "sm", "gd", "sr", "st", "sn", "sd", "si", "sk", "sl", "so", "es", "su", "sw", "sv", "tg", "ta", "te", "th", "tr", "uk",
    "ur", "uz", "vi", "cy", "xh", "yi", "yo", "zu"
};

// Get Source Language List
array<string> GetSrcLangs() {
    array<string> ret = LangTable;
    return ret;
}

// Get Destination Language List
array<string> GetDstLangs() {
    array<string> ret = LangTable;
    return ret;
}

// Login Interface for entering model name + API URL and API Key
string ServerLogin(string User, string Pass) {
    // Trim whitespace
    User = User.Trim();
    Pass = Pass.Trim();

    // 根据是否含有 '|' 分割模型名称与 API 源地址
    int sepPos = User.find("|");
    string userModel = "";
    string customApiUrl = "";

    if (sepPos != -1) {
        userModel = User.substr(0, sepPos).Trim();
        customApiUrl = User.substr(sepPos + 1).Trim();
    } else {
        // 仅提供了模型名称
        userModel = User;
        customApiUrl = "";
    }

    // Validate model name
    if (userModel.empty()) {
        HostPrintUTF8("{$CP0=Model name not entered. Please enter a valid model name.$}\n");
        userModel = "deepseek-chat"; // Default to deepseek-chat
    }

    // 如果有自定义 API URL，则使用；否则使用默认的 apiUrl
    if (!customApiUrl.empty()) {
        apiUrl = customApiUrl;
    } else {
        apiUrl = "https://api.deepseek.com/v1/chat/completions"; // DeepSeek默认API地址
    }

    // Validate API Key
    if (Pass.empty()) {
        HostPrintUTF8("{$CP0=API Key not configured. Please enter a valid API Key.$}\n");
        return "fail";
    }

    // 保存到全局变量
    selected_model = userModel;
    api_key = Pass;

    // 保存设置到临时存储
    HostSaveString("api_key", api_key);
    HostSaveString("selected_model", selected_model);
    HostSaveString("apiUrl", apiUrl);

    HostPrintUTF8("{$CP0=API Key and model name (plus API URL) successfully configured.$}\n");
    return "200 ok";
}

// Logout Interface to clear model name and API Key
void ServerLogout() {
    api_key = "";
    selected_model = "deepseek-chat";
    apiUrl = "https://api.deepseek.com/v1/chat/completions"; // 还原默认
    HostSaveString("api_key", "");
    HostSaveString("selected_model", selected_model);
    HostSaveString("apiUrl", apiUrl);
    HostPrintUTF8("{$CP0=Successfully logged out.$}\n");
}

// JSON String Escape Function
string JsonEscape(const string &in input) {
    string output = input;
    output.replace("\\", "\\\\");
    output.replace("\"", "\\\"");
    output.replace("\n", "\\n");
    output.replace("\r", "\\r");
    output.replace("\t", "\\t");
    return output;
}

// Global variables for storing previous subtitles
array<string> subtitleHistory;
string UNICODE_RLE = "\u202B"; // For Right-to-Left languages

// Function to estimate token count based on character length
int EstimateTokenCount(const string &in text) {
    // Rough estimation: average 4 characters per token
    return int(float(text.length()) / 4);
}

// Function to get the model's maximum context length
int GetModelMaxTokens(const string &in modelName) {
    // Define maximum tokens for known models
    if (modelName == "deepseek-chat") {
        return 4096; // DeepSeek模型的默认最大token数
    } else {
        // Default to a conservative limit
        return 4096;
    }
}

// Translation Function
string Translate(string Text, string &in SrcLang, string &in DstLang) {
    // Load API key, model name, and apiUrl from temporary storage
    api_key = HostLoadString("api_key", "");
    selected_model = HostLoadString("selected_model", "deepseek-chat");
    apiUrl = HostLoadString("apiUrl", "https://api.deepseek.com/v1/chat/completions");

    if (api_key.empty()) {
        HostPrintUTF8("{$CP0=API Key not configured. Please enter it in the settings menu.$}\n");
        return "翻译失败"; // 返回明确的错误提示
    }

    if (DstLang.empty() || DstLang == "{$CP0=Auto Detect$}") {
        HostPrintUTF8("{$CP0=Target language not specified. Please select a target language.$}\n");
        return "翻译失败"; // 返回明确的错误提示
    }

    if (SrcLang.empty() || SrcLang == "{$CP0=Auto Detect$}") {
        SrcLang = "";
    }

    // Add the current subtitle to the history
    subtitleHistory.insertLast(Text);

    // Get the model's maximum token limit
    int maxTokens = GetModelMaxTokens(selected_model);

    // Build the context from the subtitle history
    string context = "";
    int tokenCount = EstimateTokenCount(Text); // Tokens used by the current subtitle
    int i = int(subtitleHistory.length()) - 2; // Start from the previous subtitle
    while (i >= 0 && tokenCount < (maxTokens - 1000)) { // Reserve tokens for response and prompt
        string subtitle = subtitleHistory[i];
        int subtitleTokens = EstimateTokenCount(subtitle);
        tokenCount += subtitleTokens;
        if (tokenCount < (maxTokens - 1000)) {
            context = subtitle + "\n" + context;
        }
        i--;
    }

    // Limit the size of subtitleHistory to prevent it from growing indefinitely
    if (subtitleHistory.length() > 1000) {
        subtitleHistory.removeAt(0);
    }

    // Construct the prompt
    string prompt = "You are a professional translator. Please translate the following subtitle, output only translated results. If content that violates the Terms of Service appears, just output the translation result that complies with safety standards.";
    if (!SrcLang.empty()) {
        prompt += " from " + SrcLang;
    }
    prompt += " to " + DstLang + ". Use the context provided to maintain coherence.\n";
    if (!context.empty()) {
        prompt += "Context:\n" + context + "\n";
    }
    prompt += "Subtitle to translate:\n" + Text;

    // JSON escape
    string escapedPrompt = JsonEscape(prompt);

    // Request data
    string requestData = "{\"model\":\"" + selected_model + "\","
                         "\"messages\":[{\"role\":\"user\",\"content\":\"" + escapedPrompt + "\"}],"
                         "\"max_tokens\":1000,\"temperature\":0}";

    string headers = "Authorization: Bearer " + api_key + "\nContent-Type: application/json";

    // Send request
    string response = HostUrlGetString(apiUrl, UserAgent, headers, requestData);
    if (response.empty()) {
        HostPrintUTF8("{$CP0=Translation request failed. Please check network connection or API Key.$}\n");
        return "翻译失败"; // 返回明确的错误提示
    }

    // Parse response
    JsonReader Reader;
    JsonValue Root;
    if (!Reader.parse(response, Root)) {
        HostPrintUTF8("{$CP0=Failed to parse API response.$}\n");
        return "翻译失败"; // 返回明确的错误提示
    }

    JsonValue choices = Root["choices"];
    if (choices.isArray() && choices[0]["message"]["content"].isString()) {
        string translatedText = choices[0]["message"]["content"].asString();

        // 处理多行翻译结果：只取最后一行
        translatedText = translatedText.Trim(); // 去除多余的空格
        if (translatedText.find("\n") != -1) {
            array<string> lines = translatedText.split("\n");
            translatedText = lines[lines.length() - 1].Trim(); // 取最后一行
        }

        // 处理 RTL 语言
        if (DstLang == "fa" || DstLang == "ar" || DstLang == "he") {
            translatedText = UNICODE_RLE + translatedText;
        }

        SrcLang = "UTF8";
        DstLang = "UTF8";
        return translatedText;
    }

    // Handle API errors
    if (Root["error"]["message"].isString()) {
        string errorMessage = Root["error"]["message"].asString();
        HostPrintUTF8("{$CP0=API Error: $}" + errorMessage + "\n");
    } else {
        HostPrintUTF8("{$CP0=Translation failed. Please check input parameters or API Key configuration.$}\n");
    }

    return "翻译失败"; // 返回明确的错误提示
}

// Plugin Initialization
void OnInitialize() {
    HostPrintUTF8("{$CP0=DeepSeek translation plugin loaded.$}\n");
    // Load model name, API Key, and API URL from temporary storage (if saved)
    api_key = HostLoadString("api_key", "");
    selected_model = HostLoadString("selected_model", "deepseek-chat");
    apiUrl = HostLoadString("apiUrl", "https://api.deepseek.com/v1/chat/completions");
    if (!api_key.empty()) {
        HostPrintUTF8("{$CP0=Saved API Key, model name, and API URL loaded.$}\n");
    }
}

// Plugin Finalization
void OnFinalize() {
    HostPrintUTF8("{$CP0=DeepSeek translation plugin unloaded.$}\n");
}

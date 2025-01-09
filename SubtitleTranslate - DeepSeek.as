/*
    Real-time subtitle translation for PotPlayer using DeepSeek API
*/

// Plugin Information Functions
string GetTitle() {
    return "{$CP0=DeepSeek Translate$}";
}

string GetVersion() {
    return "0.2";
}

string GetDesc() {
    return "{$CP0=Real-time subtitle translation using DeepSeek$}";
}

string GetLoginTitle() {
    return "{$CP0=API Key Configuration$}";
}

string GetLoginDesc() {
    return "{$CP0=Please enter your API Key.$}";
}

string GetPasswordText() {
    return "{$CP0=API Key:$}";
}

// Global Variables
string api_key = "";
string selected_model = "deepseek-chat"; // Default model
string apiUrl = "https://api.deepseek.com/v1/chat/completions"; // DeepSeek API URL
string UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)";
int maxRetries = 3; // Maximum number of retries for translation
int retryDelay = 1000; // Delay between retries in milliseconds

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

// Login Interface for entering API Key
string ServerLogin(string User, string Pass) {
    // Trim whitespace
    Pass = Pass.Trim();

    // Validate API Key
    if (Pass.empty()) {
        HostPrintUTF8("{$CP0=API Key not configured. Please enter a valid API Key.$}\n");
        return "fail: API Key is empty";
    }

    // Save API Key to global variable
    api_key = Pass;

    // Save API Key to temporary storage
    HostSaveString("api_key", api_key);

    HostPrintUTF8("{$CP0=API Key successfully configured.$}\n");
    return "200 ok";
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

// Translation Function with Retry Mechanism
string Translate(string Text, string &in SrcLang, string &in DstLang) {
    // Load API key from temporary storage
    api_key = HostLoadString("api_key", "");

    if (api_key.empty()) {
        HostPrintUTF8("{$CP0=API Key not configured. Please enter it in the settings menu.$}\n");
        return "Translation failed: API Key not configured";
    }

    if (DstLang.empty() || DstLang == "{$CP0=Auto Detect$}") {
        HostPrintUTF8("{$CP0=Target language not specified. Please select a target language.$}\n");
        return "Translation failed: Target language not specified";
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

    // Retry mechanism
    int retryCount = 0;
    while (retryCount < maxRetries) {
        // Send request
        string response = HostUrlGetString(apiUrl, UserAgent, headers, requestData);
        if (response.empty()) {
            HostPrintUTF8("{$CP0=Translation request failed. Retrying...$}\n");
            retryCount++;
            HostSleep(retryDelay); // Delay before retrying
            continue;
        }

        // Parse response
        JsonReader Reader;
        JsonValue Root;
        if (!Reader.parse(response, Root)) {
            HostPrintUTF8("{$CP0=Failed to parse API response. Retrying...$}\n");
            retryCount++;
            HostSleep(retryDelay); // Delay before retrying
            continue;
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
            retryCount++;
            HostSleep(retryDelay); // Delay before retrying
        } else {
            HostPrintUTF8("{$CP0=Translation failed. Retrying...$}\n");
            retryCount++;
            HostSleep(retryDelay); // Delay before retrying
        }
    }

    // If all retries fail, return an error message
    HostPrintUTF8("{$CP0=Translation failed after maximum retries.$}\n");
    return "Translation failed: Maximum retries reached";
}

// Plugin Initialization
void OnInitialize() {
    HostPrintUTF8("{$CP0=DeepSeek translation plugin loaded.$}\n");
    // Load API Key from temporary storage (if saved)
    api_key = HostLoadString("api_key", "");
    if (!api_key.empty()) {
        HostPrintUTF8("{$CP0=Saved API Key loaded.$}\n");
    }
}

// Plugin Finalization
void OnFinalize() {
    HostPrintUTF8("{$CP0=DeepSeek translation plugin unloaded.$}\n");
}

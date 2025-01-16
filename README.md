# PotPlayer DeepSeek Translate Plugin

![GitHub License](https://img.shields.io/badge/license-MIT-blue.svg)
![GitHub Stars](https://img.shields.io/github/stars/Liu8Can/PotPlayer_DeepSeek_Translate?style=social)
![GitHub Forks](https://img.shields.io/github/forks/Liu8Can/PotPlayer_DeepSeek_Translate?style=social)

---

## 📖 简介 / Introduction

本仓库是基于 [Felix3322/PotPlayer_Chatgpt_Translate](https://github.com/Felix3322/PotPlayer_Chatgpt_Translate) 修改而来，专为 PotPlayer 设计的实时字幕翻译插件，适配 **DeepSeek API**。通过集成 DeepSeek 的强大文本生成能力，该插件能够在观看视频时实时翻译字幕，打破语言障碍，提升您的观影体验。

This repository is a modified version of [Felix3322/PotPlayer_Chatgpt_Translate](https://github.com/Felix3322/PotPlayer_Chatgpt_Translate), designed for PotPlayer with support for **DeepSeek API**. By leveraging DeepSeek's powerful text generation capabilities, this plugin enables real-time subtitle translation while watching videos, breaking language barriers and enhancing your viewing experience.

---

## 🚀 功能特性 / Features

- **实时翻译**：在播放视频时自动翻译字幕。
- **多语言支持**：支持多种语言的翻译。
- **简单配置**：只需填入 DeepSeek API Key，无需输入模型名或请求接口。
- **轻量易用**：插件体积小，安装简单，即插即用。

---

## 🛠️ 安装与使用 / Installation & Usage

### 1. **下载插件**

- 从 [Releases](https://github.com/Liu8Can/PotPlayer_DeepSeek_Translate/releases) 下载最新版本的插件文件。
- **不想折腾的的直接下载 `installer.exe` 即可一键安装**

### 2. **安装插件**

- 解压后将 `SubtitleTranslate - DeepSeek.as`和 `SubtitleTranslate - DeepSeek.ico`两个文件复制到 PotPlayer 的翻译插件目录中，例如：
  ```
  D:\Program Files\DAUM\PotPlayer\Extension\Subtitle\Translate
  ```

### 3. **配置 API Key**

1. 打开 PotPlayer，右键点击播放器界面，选择 **选项/偏好设置**。
2. 在左侧菜单中找到 **字幕** -> **实时字幕翻译** -> **实时字幕翻译设置**。
3. 在插件设置中，填入您的 **DeepSeek API Key**。一定要点击——账户设置——确定。测试——确定。以上两步操作，确保新的参数被注入。刚开始几段话会显示乱码，不要担心，因为网络请求刚开始并没有返回参数。可以尝试快进下。同时在请求中，有概率返回很多字幕的内容，已经尽可能减少了，但还没法完全避免。
4. 保存设置并重启 PotPlayer。

### 4. **开始使用**

- 播放视频时，插件会自动翻译字幕并显示在屏幕上。

---

## 📜 协议 / License

本项目采用 **MIT 许可证**，详情请参阅 [LICENSE](LICENSE) 文件。

---

## 🙏 致谢 / Acknowledgments

- 感谢 [Felix3322](https://github.com/Felix3322) 提供的原始代码库 [PotPlayer_Chatgpt_Translate](https://github.com/Felix3322/PotPlayer_Chatgpt_Translate)。
- 感谢 [yxyxyz6](https://github.com/yxyxyz6) 提供的修改参考 [yxyxyz6/PotPlayer_ollama_Translate](https://github.com/yxyxyz6/PotPlayer_ollama_Translate/tree/main)
- 感谢 **DeepSeek** 提供的强大模型支持，为插件提供了高效的翻译能力。

---

## 📧 联系与支持 / Contact & Support

如果您有任何问题或建议，欢迎通过以下方式联系我：

- **Email**: [liucan@example.com](mailto:liucan@example.com)
- **GitHub Issues**: [提交 Issue](https://github.com/Liu8Can/PotPlayer_DeepSeek_Translate/issues)

---

## 🌟 Star & Fork

如果这个项目对您有帮助，欢迎给个 ⭐️ **Star** 支持一下！也欢迎 **Fork** 并贡献您的代码！

---

**Happy Watching! 🎥**

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';


// ============================================================
// KEYBOARD INTENTS
// ============================================================

class SendMessageIntent extends Intent {
  const SendMessageIntent();
}

class InsertNewLineIntent extends Intent {
  const InsertNewLineIntent();
}


// ============================================================
// MESSAGE TYPES
// ============================================================

enum MessageType {
  user,
  ai,
  system,
  error,
}


// ============================================================
// CHAT MESSAGE
// ============================================================

class ChatMessage {
  final MessageType type;
  final String text;
  final List<dynamic>? sources;

  const ChatMessage({
    required this.type,
    required this.text,
    this.sources,
  });
}


// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


// ============================================================
// HOME SCREEN STATE
// ============================================================

class _HomeScreenState
    extends State<HomeScreen>
    with TickerProviderStateMixin {
  final ApiService apiService = ApiService();

  final TextEditingController questionController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  final FocusNode questionFocusNode =
      FocusNode();

  final List<ChatMessage> messages = [];

  bool isUploading = false;
  bool isAsking = false;
  bool documentUploaded = false;

  String? documentName;

  String uploadStage = '';
  double uploadProgress = 0;

  late final AnimationController uploadController;
  late final AnimationController messageController;


  @override
  void initState() {
    super.initState();

    uploadController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1200,
      ),
    );

    messageController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 450,
      ),
    );
  }


  @override
  void dispose() {
    questionController.dispose();
    scrollController.dispose();
    questionFocusNode.dispose();

    uploadController.dispose();
    messageController.dispose();

    super.dispose();
  }


  // ============================================================
  // THEME HELPERS
  // ============================================================

  ThemeData get appTheme =>
      Theme.of(context);

  ColorScheme get colors =>
      appTheme.colorScheme;


  // ============================================================
  // UPLOAD PDF
  // ============================================================

  Future<void> uploadPdf() async {
    if (isUploading) {
      return;
    }

    try {
      final result =
          await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );

      if (result == null) {
        return;
      }

      final file = result.files.single;

      if (file.bytes == null) {
        _showMessage(
          'Could not read the PDF.',
          error: true,
        );
        return;
      }

      setState(() {
        isUploading = true;
        uploadProgress = 0.05;
        uploadStage = 'Uploading document...';
      });

      uploadController.repeat();

      _simulateUploadStages();

      final response =
          await apiService.uploadPdf(
        file.name,
        file.bytes!,
      );

      uploadController.stop();
      uploadController.reset();

      if (!mounted) {
        return;
      }

      setState(() {
        isUploading = false;
        uploadProgress = 1;
        uploadStage = 'Ready';
        documentUploaded = true;
        documentName =
            response['filename']?.toString() ??
                file.name;
      });

      messages.add(
        ChatMessage(
          type: MessageType.system,
          text:
              '${file.name} is ready. Ask me anything about it.',
        ),
      );

      _scrollToBottom();

      _showMessage(
        'Document processed successfully.',
      );
    } catch (e) {
      uploadController.stop();
      uploadController.reset();

      if (!mounted) {
        return;
      }

      setState(() {
        isUploading = false;
        uploadProgress = 0;
        uploadStage = '';
      });

      _showMessage(
        'Upload failed: $e',
        error: true,
      );
    }
  }


  // ============================================================
  // UPLOAD STAGES
  // ============================================================

  Future<void> _simulateUploadStages() async {
    const stages = [
      (
        'Uploading document...',
        0.15,
      ),
      (
        'Extracting text...',
        0.35,
      ),
      (
        'Splitting document...',
        0.55,
      ),
      (
        'Creating embeddings...',
        0.75,
      ),
      (
        'Building vector index...',
        0.90,
      ),
    ];

    for (final stage in stages) {
      await Future.delayed(
        const Duration(
          milliseconds: 650,
        ),
      );

      if (!mounted || !isUploading) {
        return;
      }

      setState(() {
        uploadStage = stage.$1;
        uploadProgress = stage.$2;
      });
    }
  }


  // ============================================================
  // ASK QUESTION
  // ============================================================

  Future<void> askQuestion() async {
    final question =
        questionController.text.trim();

    if (question.isEmpty) {
      return;
    }

    if (!documentUploaded) {
      _showMessage(
        'Upload a PDF first.',
        error: true,
      );
      return;
    }

    if (isAsking) {
      return;
    }

    questionController.clear();

    FocusScope.of(context).unfocus();

    await messageController.forward(
      from: 0,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      messages.add(
        ChatMessage(
          type: MessageType.user,
          text: question,
        ),
      );

      isAsking = true;
    });

    messageController.reset();

    _scrollToBottom();

    try {
      final response =
          await apiService.askQuestion(
        question,
      );

      if (!mounted) {
        return;
      }

      final answer =
          response['answer']?.toString() ??
              'No answer was returned.';

      final sources =
          response['sources'] is List
              ? response['sources'] as List
              : <dynamic>[];

      setState(() {
        isAsking = false;

        messages.add(
          ChatMessage(
            type: MessageType.ai,
            text: answer,
            sources: sources,
          ),
        );
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isAsking = false;

        messages.add(
          const ChatMessage(
            type: MessageType.error,
            text:
                'I could not generate an answer. Please try again.',
          ),
        );
      });

      _scrollToBottom();
    }
  }


  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!scrollController.hasClients) {
          return;
        }

        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 500,
          ),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }


  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    final snackTextColor = error
        ? colors.onError
        : colors.onInverseSurface;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            error
                ? colors.error
                : colors.inverseSurface,
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: snackTextColor,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: snackTextColor,
                ),
              ),
            ),
          ],
        ),
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }


  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          colors.surface,
      body:
          LayoutBuilder(
        builder:
            (
          context,
          constraints,
        ) {
          if (constraints.maxWidth < 800) {
            return _mobileLayout();
          }

          return _desktopLayout();
        },
      ),
    );
  }


  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _desktopLayout() {
    return Row(
      children: [
        _sidebar(),
        Expanded(
          child: _chatArea(),
        ),
      ],
    );
  }


  // ============================================================
  // MOBILE
  // ============================================================

  Widget _mobileLayout() {
    return Column(
      children: [
        _mobileHeader(),
        Expanded(
          child: _chatArea(),
        ),
      ],
    );
  }


  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _sidebar() {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color:
            colors.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color:
                colors.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _logo(),
                  const SizedBox(
                    width: 11,
                  ),
                  Expanded(
                    child: Text(
                      'AI Knowledge Copilot',
                      style: appTheme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 28,
              ),

              _sidebarButton(
                icon: Icons.add,
                text:
                    'New conversation',
                onTap: () {
                  setState(() {
                    messages.clear();
                  });
                },
              ),

              const SizedBox(
                height: 8,
              ),

              _sidebarButton(
                icon:
                    Icons.upload_file_outlined,
                text:
                    isUploading
                        ? 'Processing...'
                        : 'Upload PDF',
                onTap:
                    isUploading
                        ? null
                        : uploadPdf,
              ),

              const SizedBox(
                height: 28,
              ),

              Text(
                'DOCUMENT',
                style: appTheme
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                  letterSpacing: 1.3,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              _documentTile(),

              const Spacer(),

              _themeButton(),

              const SizedBox(
                height: 12,
              ),

              Container(
                padding:
                    const EdgeInsets.all(14),
                decoration:
                    BoxDecoration(
                  color:
                      colors.primaryContainer
                          .withValues(
                    alpha: 0.45,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color:
                          colors.primary,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        'RAG • FAISS • Groq',
                        style: appTheme
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                          color:
                              colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ============================================================
  // MOBILE HEADER
  // ============================================================

  Widget _mobileHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 65,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color:
              colors.surfaceContainerLow,
          border: Border(
            bottom: BorderSide(
              color:
                  colors.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            _logo(),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Text(
                'AI Knowledge Copilot',
                style: appTheme
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),

            IconButton(
              onPressed:
                  widget.onThemeToggle,
              tooltip:
                  widget.isDarkMode
                      ? 'Light mode'
                      : 'Dark mode',
              icon: Icon(
                widget.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),

            IconButton(
              onPressed:
                  isUploading
                      ? null
                      : uploadPdf,
              tooltip:
                  'Upload PDF',
              icon: const Icon(
                Icons.upload_file_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // CHAT AREA
  // ============================================================

  Widget _chatArea() {
    return Column(
      children: [
        _chatHeader(),

        Expanded(
          child:
              messages.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      controller:
                          scrollController,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      itemCount:
                          messages.length +
                              (isAsking
                                  ? 1
                                  : 0),
                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        if (
                            isAsking &&
                            index ==
                                messages.length
                        ) {
                          return _thinkingBubble();
                        }

                        return _messageBubble(
                          messages[index],
                        );
                      },
                    ),
        ),

        _composer(),
      ],
    );
  }


  // ============================================================
  // CHAT HEADER
  // ============================================================

  Widget _chatHeader() {
    return Container(
      height: 65,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      decoration:
          BoxDecoration(
        color:
            colors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color:
                colors.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Document Chat',
                style: appTheme
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              Text(
                documentUploaded
                    ? documentName ??
                        'Document ready'
                    : 'Upload a document to begin',
                style: appTheme
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                  color:
                      colors.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const Spacer(),

          if (documentUploaded)
            _readyBadge(),
        ],
      ),
    );
  }


  // ============================================================
  // READY BADGE
  // ============================================================

  Widget _readyBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.green.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.circle,
            size: 7,
            color: Colors.green,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            'Ready',
            style: appTheme
                .textTheme
                .labelSmall
                ?.copyWith(
              color:
                  Colors.green.shade700,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }


  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween:
                  Tween(
                begin: 0.8,
                end: 1,
              ),
              duration:
                  const Duration(
                milliseconds: 800,
              ),
              curve:
                  Curves.easeOutBack,
              builder:
                  (
                context,
                value,
                child,
              ) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child:
                  _largeLogo(),
            ),

            const SizedBox(
              height: 24,
            ),

            Text(
              'What would you like to know?',
              textAlign:
                  TextAlign.center,
              style: appTheme
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight:
                    FontWeight.w800,
                letterSpacing:
                    -0.5,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              documentUploaded
                  ? 'Ask a question about your document.'
                  : 'Upload a PDF and start a conversation.',
              textAlign:
                  TextAlign.center,
              style: appTheme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color:
                    colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            if (!documentUploaded)
              FilledButton.icon(
                onPressed:
                    uploadPdf,
                icon: const Icon(
                  Icons.upload_file_outlined,
                ),
                label:
                    const Text(
                  'Upload PDF',
                ),
              ),

            if (documentUploaded)
              Wrap(
                alignment:
                    WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _suggestion(
                    'Summarize this document',
                  ),
                  _suggestion(
                    'What are the key points?',
                  ),
                  _suggestion(
                    'Explain the main topic',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // SUGGESTION
  // ============================================================

  Widget _suggestion(
    String text,
  ) {
    return ActionChip(
      label:
          Text(text),
      onPressed: () {
        questionController.text =
            text;
        askQuestion();
      },
      backgroundColor:
          colors.surfaceContainerHigh,
      side:
          BorderSide(
        color:
            colors.outlineVariant,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
    );
  }


  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _messageBubble(
    ChatMessage message,
  ) {
    final isUser =
        message.type ==
            MessageType.user;

    final isSystem =
        message.type ==
            MessageType.system;

    final isError =
        message.type ==
            MessageType.error;


    if (isSystem) {
      return TweenAnimationBuilder<double>(
        duration:
            const Duration(
          milliseconds: 450,
        ),
        tween:
            Tween(
          begin: 0,
          end: 1,
        ),
        curve:
            Curves.easeOut,
        builder:
            (
          context,
          value,
          child,
        ) {
          return Opacity(
            opacity: value,
            child:
                Transform.translate(
              offset:
                  Offset(
                0,
                10 * (1 - value),
              ),
              child: child,
            ),
          );
        },
        child:
            Padding(
          padding:
              const EdgeInsets.only(
            bottom: 18,
          ),
          child:
              Center(
            child:
                Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration:
                  BoxDecoration(
                color:
                    colors.primaryContainer,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child:
                  Text(
                message.text,
                style: appTheme
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                  color:
                      colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      );
    }


    return TweenAnimationBuilder<double>(
      duration:
          const Duration(
        milliseconds: 450,
      ),
      tween:
          Tween(
        begin: 0,
        end: 1,
      ),
      curve:
          Curves.easeOutCubic,
      builder:
          (
        context,
        value,
        child,
      ) {
        return Opacity(
          opacity: value,
          child:
              Transform.translate(
            offset:
                Offset(
              isUser
                  ? 35 * (1 - value)
                  : 0,
              20 * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child:
          Padding(
        padding:
            const EdgeInsets.only(
          bottom: 24,
        ),
        child:
            Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisAlignment:
              isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: [
            if (!isUser)
              _aiAvatar(),

            if (!isUser)
              const SizedBox(
                width: 10,
              ),

            Flexible(
              child:
                  Container(
                constraints:
                    const BoxConstraints(
                  maxWidth: 750,
                ),
                padding:
                    const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(
                  color:
                      isUser
                          ? colors.primary
                          : isError
                              ? colors.errorContainer
                              : colors.surfaceContainerHigh,
                  borderRadius:
                      BorderRadius.only(
                    topLeft:
                        const Radius.circular(18),
                    topRight:
                        const Radius.circular(18),
                    bottomLeft:
                        Radius.circular(
                      isUser ? 18 : 5,
                    ),
                    bottomRight:
                        Radius.circular(
                      isUser ? 5 : 18,
                    ),
                  ),
                  border:
                      isUser
                          ? null
                          : Border.all(
                              color:
                                  colors.outlineVariant,
                            ),
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message.text,
                      style: appTheme
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        height: 1.65,
                        color:
                            isUser
                                ? colors.onPrimary
                                : isError
                                    ? colors.onErrorContainer
                                    : colors.onSurface,
                      ),
                    ),

                    if (
                        message.sources !=
                            null &&
                        message.sources!
                            .isNotEmpty
                    ) ...[
                      const SizedBox(
                        height: 18,
                      ),
                      _sourceSection(
                        message.sources!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // AI AVATAR
  // ============================================================

  Widget _aiAvatar() {
    return Container(
      width: 34,
      height: 34,
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF6D5DFB),
            Color(0xFF9588FF),
          ],
        ),
        borderRadius:
            BorderRadius.circular(11),
      ),
      child:
          const Icon(
        Icons.auto_awesome,
        size: 17,
        color: Colors.white,
      ),
    );
  }


  // ============================================================
  // THINKING BUBBLE
  // ============================================================

  Widget _thinkingBubble() {
    return TweenAnimationBuilder<double>(
      duration:
          const Duration(
        milliseconds: 350,
      ),
      tween:
          Tween(
        begin: 0,
        end: 1,
      ),
      curve:
          Curves.easeOutBack,
      builder:
          (
        context,
        value,
        child,
      ) {
        final safeValue = value.clamp(
          0.0,
          1.0,
        );

        return Opacity(
          opacity: safeValue,
          child:
              Transform.translate(
            offset:
                Offset(
              0,
              12 * (1 - safeValue),
            ),
            child: child,
          ),
        );
      },
      child:
          Padding(
        padding:
            const EdgeInsets.only(
          bottom: 24,
        ),
        child:
            Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _aiAvatar(),

            const SizedBox(
              width: 10,
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    colors.surfaceContainerHigh,
                borderRadius:
                    BorderRadius.circular(18),
                border:
                    Border.all(
                  color:
                      colors.outlineVariant,
                ),
              ),
              child:
                  const _ThinkingDots(),
            ),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // SOURCES
  // ============================================================

  Widget _sourceSection(
    List<dynamic> sources,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        color:
            colors.surfaceContainerLow,
        borderRadius:
            BorderRadius.circular(12),
        border:
            Border.all(
          color:
              colors.outlineVariant,
        ),
      ),
      child:
          Column(
        children:
            List.generate(
          sources.length,
          (index) {
            final source =
                sources[index];

            final Map<String, dynamic>
                sourceMap =
                source is Map
                    ? Map<String, dynamic>.from(
                        source,
                      )
                    : <String, dynamic>{};

            final page =
                sourceMap['page'];

            final content =
                sourceMap['content']
                        ?.toString() ??
                    '';

            return ExpansionTile(
              dense: true,
              title:
                  Text(
                'Source ${index + 1}',
                style: appTheme
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              subtitle:
                  Text(
                'Page ${page ?? 'Unknown'}',
                style: appTheme
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                  color:
                      colors.onSurfaceVariant,
                ),
              ),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    14,
                    0,
                    14,
                    14,
                  ),
                  child:
                      Align(
                    alignment:
                        Alignment.centerLeft,
                    child:
                        SelectableText(
                      content,
                      style: appTheme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        height: 1.5,
                        color:
                            colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  // ============================================================
  // COMPOSER
  // ============================================================

  Widget _composer() {
    return SafeArea(
      top: false,
      child:
          Container(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          16,
        ),
        decoration:
            BoxDecoration(
          color:
              colors.surfaceContainerLow,
          border:
              Border(
            top:
                BorderSide(
              color:
                  colors.outlineVariant,
            ),
          ),
        ),
        child:
            ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 900,
          ),
          child:
              Shortcuts(
            shortcuts:
                const <ShortcutActivator,
                    Intent>{
              SingleActivator(
                LogicalKeyboardKey.enter,
                shift: true,
              ):
                  InsertNewLineIntent(),

              SingleActivator(
                LogicalKeyboardKey.enter,
              ):
                  SendMessageIntent(),
            },
            child:
                Actions(
              actions:
                  <Type,
                      Action<Intent>>{
                SendMessageIntent:
                    CallbackAction<
                        SendMessageIntent>(
                  onInvoke:
                      (intent) {
                    if (
                        !isAsking &&
                        documentUploaded
                    ) {
                      askQuestion();
                    }
                    return null;
                  },
                ),

                InsertNewLineIntent:
                    CallbackAction<
                        InsertNewLineIntent>(
                  onInvoke:
                      (intent) {
                    final value =
                        questionController
                            .value;

                    final text =
                        value.text;

                    final selection =
                        value.selection;

                    if (!selection.isValid) {
                      return null;
                    }

                    final newText =
                        '${text.substring(0, selection.start)}\n${text.substring(selection.end)}';

                    questionController.value =
                        TextEditingValue(
                      text: newText,
                      selection:
                          TextSelection.collapsed(
                        offset:
                            selection.start + 1,
                      ),
                    );

                    return null;
                  },
                ),
              },
              child:
                  Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child:
                        TextField(
                      controller:
                          questionController,
                      focusNode:
                          questionFocusNode,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType:
                          TextInputType.multiline,
                      decoration:
                          InputDecoration(
                        hintText:
                            documentUploaded
                                ? 'Message AI Knowledge Copilot...'
                                : 'Upload a PDF to start chatting',
                        hintStyle:
                            TextStyle(
                          color:
                              colors.onSurfaceVariant
                                  .withValues(
                            alpha: 0.65,
                          ),
                        ),
                        filled:
                            true,
                        fillColor:
                            colors.surfaceContainerHigh,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                              BorderSide(
                            color:
                                colors.primary,
                            width: 1.4,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 200,
                    ),
                    width: 52,
                    height: 52,
                    decoration:
                        BoxDecoration(
                      color:
                          documentUploaded &&
                                  !isAsking
                              ? colors.primary
                              : colors.surfaceContainerHighest,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child:
                        Material(
                      color:
                          Colors.transparent,
                      child:
                          InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        onTap:
                            documentUploaded &&
                                    !isAsking
                                ? askQuestion
                                : null,
                        child:
                            Center(
                          child:
                              isAsking
                                  ? SizedBox(
                                      width: 19,
                                      height: 19,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            colors.onPrimary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.arrow_upward,
                                      color:
                                          documentUploaded
                                              ? colors.onPrimary
                                              : colors.onSurfaceVariant,
                                    ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ============================================================
  // DOCUMENT TILE
  // ============================================================

  Widget _documentTile() {
    if (!documentUploaded && !isUploading) {
      return Container(
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color:
              colors.surfaceContainerHigh,
          borderRadius:
              BorderRadius.circular(12),
        ),
        child:
            Row(
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 18,
              color:
                  colors.onSurfaceVariant,
            ),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child:
                  Text(
                'No document uploaded',
                style: appTheme
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                  color:
                      colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isUploading) {
      return _uploadProgressCard();
    }

    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color:
            colors.primaryContainer,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child:
          Row(
        children: [
          const Icon(
            Icons.picture_as_pdf,
            color:
                Colors.redAccent,
            size: 21,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child:
                Text(
              documentName ??
                  'Document',
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: appTheme
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                fontWeight:
                    FontWeight.w700,
                color:
                    colors.onPrimaryContainer,
              ),
            ),
          ),

          const Icon(
            Icons.check_circle,
            color:
                Colors.green,
            size: 17,
          ),
        ],
      ),
    );
  }


  // ============================================================
  // UPLOAD PROGRESS
  // ============================================================

  Widget _uploadProgressCard() {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            colors.primaryContainer,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RotationTransition(
                turns:
                    uploadController,
                child:
                    Icon(
                  Icons.sync,
                  color:
                      colors.primary,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    Text(
                  uploadStage,
                  style: appTheme
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child:
                LinearProgressIndicator(
              value:
                  uploadProgress,
              minHeight: 6,
              backgroundColor:
                  colors.surface,
              color:
                  colors.primary,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            '${(uploadProgress * 100).round()}%',
            style: appTheme
                .textTheme
                .labelSmall
                ?.copyWith(
              color:
                  colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }


  // ============================================================
  // SIDEBAR BUTTON
  // ============================================================

  Widget _sidebarButton({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(12),
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          child:
              Row(
            children: [
              Icon(
                icon,
                size: 19,
                color:
                    colors.onSurfaceVariant,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child:
                    Text(
                  text,
                  style: appTheme
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ============================================================
  // THEME BUTTON
  // ============================================================

  Widget _themeButton() {
    return Material(
      color:
          colors.surfaceContainerHigh,
      borderRadius:
          BorderRadius.circular(12),
      child:
          InkWell(
        onTap:
            widget.onThemeToggle,
        borderRadius:
            BorderRadius.circular(12),
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          child:
              Row(
            children: [
              Icon(
                widget.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 18,
                color:
                    colors.onSurfaceVariant,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child:
                    Text(
                  widget.isDarkMode
                      ? 'Light mode'
                      : 'Dark mode',
                  style: appTheme
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ============================================================
  // LOGOS
  // ============================================================

  Widget _logo() {
    return Container(
      width: 38,
      height: 38,
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF6D5DFB),
            Color(0xFF9588FF),
          ],
        ),
        borderRadius:
            BorderRadius.circular(11),
      ),
      child:
          const Icon(
        Icons.auto_awesome,
        color:
            Colors.white,
        size: 19,
      ),
    );
  }


  Widget _largeLogo() {
    return Container(
      width: 82,
      height: 82,
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF6D5DFB),
            Color(0xFF9588FF),
          ],
        ),
        borderRadius:
            BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color:
                const Color(
              0xFF6D5DFB,
            ).withValues(
              alpha: 0.25,
            ),
            blurRadius: 35,
            offset:
                const Offset(0, 12),
          ),
        ],
      ),
      child:
          const Icon(
        Icons.auto_awesome,
        color:
            Colors.white,
        size: 37,
      ),
    );
  }
}


// ============================================================
// THINKING DOTS
// ============================================================

class _ThinkingDots
    extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() =>
      _ThinkingDotsState();
}


class _ThinkingDotsState
    extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 1000,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final dotColor =
        Theme.of(context)
            .colorScheme
            .onSurfaceVariant;

    return AnimatedBuilder(
      animation:
          controller,
      builder:
          (
        context,
        child,
      ) {
        return Row(
          mainAxisSize:
              MainAxisSize.min,
          children:
              List.generate(
            3,
            (index) {
              final value =
                  (controller.value +
                          index * 0.2) %
                      1;

              final scale =
                  value < 0.5
                      ? 0.7 +
                          value * 0.6
                      : 1.3 -
                          value * 0.6;

              return Transform.scale(
                scale:
                    scale,
                child:
                    Container(
                  margin:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 3,
                  ),
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(
                    color:
                        dotColor,
                    shape:
                        BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
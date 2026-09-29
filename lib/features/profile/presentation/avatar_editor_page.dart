import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/design_system/corevent_button.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/avatar_image.dart';
import 'avatar_view_model.dart';

class AvatarEditorPage extends ConsumerStatefulWidget {
  const AvatarEditorPage({super.key, required this.image});
  final Uint8List image;
  @override
  ConsumerState<AvatarEditorPage> createState() => _AvatarEditorPageState();
}

class _AvatarEditorPageState extends ConsumerState<AvatarEditorPage> {
  final controller = CropController();
  Uint8List? preview;
  bool ready = false;
  bool cropping = false;
  String? cropError;

  Future<void> _cropped(CropResult result) async {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          final bytes = await compute(finishAvatar, croppedImage);
          if (mounted) {
            setState(() {
              preview = bytes;
              cropping = false;
            });
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              cropping = false;
              cropError = 'Não foi possível preparar a foto.';
            });
          }
        }
      case CropFailure():
        setState(() {
          cropping = false;
          cropError = 'Não foi possível recortar a foto. Tente novamente.';
        });
    }
  }

  Future<void> _save() async {
    final saved = await ref
        .read(avatarViewModelProvider.notifier)
        .save(preview!);
    if (saved && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(avatarViewModelProvider);
    final blocked = state.busy || cropping;
    return PopScope(
      canPop: !blocked,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          shape: const Border(bottom: AppSurfaces.outline),
          title: Text(preview == null ? 'Ajustar foto' : 'Prévia da foto'),
          leading: IconButton(
            tooltip: 'Cancelar alteração de foto',
            onPressed: blocked ? null : () => Navigator.pop(context),
            icon: const Icon(RemixIcons.arrow_left_line),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Expanded(
                    child: preview == null
                        ? Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Arraste e use o zoom para enquadrar sua foto.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: AbsorbPointer(
                                  absorbing: blocked,
                                  child: Crop(
                                    image: widget.image,
                                    controller: controller,
                                    onCropped: _cropped,
                                    withCircleUi: true,
                                    interactive: true,
                                    fixCropRect: true,
                                    baseColor: AppColors.surface,
                                    maskColor: AppColors.surface.withAlpha(200),
                                    progressIndicator:
                                        const CircularProgressIndicator(
                                          color: AppColors.primary,
                                        ),
                                    onStatusChanged: (status) {
                                      if (mounted) {
                                        setState(
                                          () => ready =
                                              status == CropStatus.ready,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                Semantics(
                                  label: 'Prévia da nova foto de perfil',
                                  image: true,
                                  child: ClipOval(
                                    child: Image.memory(
                                      preview!,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Esta será sua foto de perfil.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'A foto atual será substituída após a confirmação.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (!state.busy && state.uploadedKey == null)
                                  TextButton(
                                    onPressed: () {
                                      ref.invalidate(avatarViewModelProvider);
                                      setState(() {
                                        preview = null;
                                        ready = false;
                                        cropError = null;
                                      });
                                    },
                                    child: const Text('Ajustar recorte'),
                                  ),
                                if (state.busy) ...[
                                  const SizedBox(height: 24),
                                  LinearProgressIndicator(
                                    value: state.confirming
                                        ? null
                                        : state.progress,
                                    color: AppColors.primary,
                                    backgroundColor:
                                        AppColors.backgroundSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.confirming
                                        ? 'Confirmando foto…'
                                        : 'Enviando foto… ${(state.progress * 100).round()}%',
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                  if (cropError != null || state.error != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        cropError ?? state.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(top: AppSurfaces.outline),
                    ),
                    child: CoreventButton(
                      label: preview == null
                          ? 'Continuar'
                          : state.error != null
                          ? 'Tentar novamente'
                          : 'Salvar foto',
                      busy: blocked,
                      onPressed: preview == null
                          ? ready
                                ? () {
                                    setState(() {
                                      cropping = true;
                                      cropError = null;
                                    });
                                    controller.crop();
                                  }
                                : null
                          : _save,
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
}

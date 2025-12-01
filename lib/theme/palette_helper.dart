import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Extracted adaptive colors from album art
class AdaptiveColors {
  final Color primary;       // Main accent color (vibrant)
  final Color surface;       // Background color
  final Color onSurface;     // Text color on background
  final Color miniPlayer;    // Darker version for mini player

  const AdaptiveColors({
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.miniPlayer,
  });

  static const fallback = AdaptiveColors(
    primary: Color(0xFF604CEC),
    surface: Color(0xFF121212),
    onSurface: Colors.white,
    miniPlayer: Color(0xFF1a1a1a),
  );
}

class PaletteHelper {
  /// Extract a color palette from an image with higher color count for better variety
  static Future<PaletteGenerator?> extractPalette(ImageProvider imageProvider) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 32, // Increased from 20 for more color variety
      );
      return palette;
    } catch (e) {
      print('⚠️ Failed to extract palette: $e');
      return null;
    }
  }

  /// Extract actual colors from the palette (not seed-based)
  static AdaptiveColors? extractAdaptiveColors(PaletteGenerator? palette, {required bool isDark}) {
    if (palette == null) return null;

    // Get primary color - prefer vibrant, then dominant
    final Color primary = palette.vibrantColor?.color ??
                         palette.lightVibrantColor?.color ??
                         palette.dominantColor?.color ??
                         const Color(0xFF604CEC);

    // Ensure primary has enough saturation to be visually distinct
    final HSLColor hslPrimary = HSLColor.fromColor(primary);
    final Color adjustedPrimary = hslPrimary.saturation < 0.3
        ? hslPrimary.withSaturation(0.5).toColor()
        : primary;

    if (isDark) {
      // Dark mode: use dark muted colors for background
      final Color surfaceBase = palette.darkMutedColor?.color ??
                                palette.mutedColor?.color ??
                                const Color(0xFF121212);

      // Darken the surface color significantly for the background
      final HSLColor hslSurface = HSLColor.fromColor(surfaceBase);
      final Color surface = hslSurface
          .withLightness((hslSurface.lightness * 0.3).clamp(0.05, 0.15))
          .toColor();

      // Mini player should be slightly lighter than expanded background but still dark
      final Color miniPlayer = hslSurface
          .withLightness((hslSurface.lightness * 0.5).clamp(0.08, 0.2))
          .withSaturation((hslSurface.saturation * 0.7).clamp(0.1, 0.4))
          .toColor();

      return AdaptiveColors(
        primary: adjustedPrimary,
        surface: surface,
        onSurface: Colors.white,
        miniPlayer: miniPlayer,
      );
    } else {
      // Light mode: use light muted colors
      final Color surfaceBase = palette.lightMutedColor?.color ??
                                palette.mutedColor?.color ??
                                Colors.white;

      final HSLColor hslSurface = HSLColor.fromColor(surfaceBase);
      final Color surface = hslSurface
          .withLightness((hslSurface.lightness).clamp(0.92, 0.98))
          .toColor();

      final Color miniPlayer = hslSurface
          .withLightness((hslSurface.lightness).clamp(0.85, 0.92))
          .toColor();

      return AdaptiveColors(
        primary: adjustedPrimary,
        surface: surface,
        onSurface: Colors.black87,
        miniPlayer: miniPlayer,
      );
    }
  }

  /// Generate color schemes from a palette (kept for backward compatibility)
  static (ColorScheme, ColorScheme)? generateColorSchemes(PaletteGenerator? palette) {
    if (palette == null) return null;

    final lightColors = extractAdaptiveColors(palette, isDark: false);
    final darkColors = extractAdaptiveColors(palette, isDark: true);

    if (lightColors == null || darkColors == null) return null;

    final lightScheme = ColorScheme(
      brightness: Brightness.light,
      primary: lightColors.primary,
      onPrimary: Colors.white,
      secondary: lightColors.primary.withOpacity(0.8),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: lightColors.surface,
      onSurface: lightColors.onSurface,
      primaryContainer: lightColors.miniPlayer,
      onPrimaryContainer: lightColors.onSurface,
    );

    final darkScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: darkColors.primary,
      onPrimary: Colors.black,
      secondary: darkColors.primary.withOpacity(0.8),
      onSecondary: Colors.black,
      error: Colors.redAccent,
      onError: Colors.black,
      surface: darkColors.surface,
      onSurface: darkColors.onSurface,
      primaryContainer: darkColors.miniPlayer,
      onPrimaryContainer: darkColors.onSurface,
    );

    return (lightScheme, darkScheme);
  }

  /// Extract color schemes from an image provider in one call
  static Future<(ColorScheme, ColorScheme)?> extractColorSchemes(ImageProvider imageProvider) async {
    final palette = await extractPalette(imageProvider);
    return generateColorSchemes(palette);
  }

  /// Get primary color for use in UI elements
  static Color? getPrimaryColor(PaletteGenerator? palette) {
    if (palette == null) return null;

    return palette.vibrantColor?.color ??
           palette.dominantColor?.color ??
           palette.lightVibrantColor?.color;
  }

  /// Get background color for use in UI
  static Color? getBackgroundColor(PaletteGenerator? palette, {required bool isDark}) {
    if (palette == null) return null;

    if (isDark) {
      return palette.darkMutedColor?.color ??
             palette.mutedColor?.color?.withOpacity(0.3) ??
             const Color(0xFF1a1a1a);
    } else {
      return palette.lightMutedColor?.color ??
             palette.mutedColor?.color?.withOpacity(0.9) ??
             Colors.white;
    }
  }
}

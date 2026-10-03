import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
	static final light = ThemeData(
		useMaterial3: true,
		scaffoldBackgroundColor: AppColors.canvas,
		colorScheme: ColorScheme.fromSeed(
			seedColor: AppColors.green,
			surface: AppColors.surface,
			error: AppColors.danger,
		),
		appBarTheme: const AppBarTheme(
			backgroundColor: AppColors.canvas,
			foregroundColor: AppColors.ink,
			centerTitle: false,
			elevation: 0,
		),
		inputDecorationTheme: InputDecorationTheme(
			filled: true,
			fillColor: AppColors.surface,
			contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
			border: OutlineInputBorder(
				borderRadius: BorderRadius.circular(8),
				borderSide: const BorderSide(color: AppColors.border),
			),
			enabledBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(8),
				borderSide: const BorderSide(color: AppColors.border),
			),
			focusedBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(8),
				borderSide: const BorderSide(color: AppColors.green, width: 1.5),
			),
		),
		cardTheme: CardThemeData(
			color: AppColors.surface,
			elevation: 0,
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(8),
				side: const BorderSide(color: AppColors.border),
			),
		),
		textTheme: const TextTheme(
			headlineMedium: TextStyle(
				color: AppColors.ink,
				fontSize: 28,
				fontWeight: FontWeight.w700,
			),
			titleMedium: TextStyle(
				color: AppColors.ink,
				fontWeight: FontWeight.w600,
			),
			bodyMedium: TextStyle(color: AppColors.ink),
			bodySmall: TextStyle(color: AppColors.mutedInk),
		),
	);
}

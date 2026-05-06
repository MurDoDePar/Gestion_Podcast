import 'package:flutter/material.dart';

class ThemeCategory {
  final String name;
  final IconData icon;
  final String description;
  final List<SubTheme> subThemes;

  const ThemeCategory({
    required this.name,
    required this.icon,
    required this.description,
    required this.subThemes,
  });
}

class SubTheme {
  final String name;
  final IconData icon;
  final String searchTerm;
  final String genreId;

  const SubTheme({
    required this.name,
    required this.icon,
    required this.searchTerm,
    required this.genreId,
  });
}

const List<ThemeCategory> themesList = [
  ThemeCategory(
    name: "Actualités",
    icon: Icons.newspaper,
    description: "Les informations et l'actualité mondiale.",
    subThemes: [
      SubTheme(
          name: "Actualités",
          icon: Icons.article,
          searchTerm: "News",
          genreId: "1489"),
      SubTheme(
          name: "Affaires",
          icon: Icons.business_center,
          searchTerm: "Business",
          genreId: "1321"),
      SubTheme(
          name: "Gouvernement",
          icon: Icons.account_balance,
          searchTerm: "Government",
          genreId: "1511"),
      SubTheme(
          name: "Technologies",
          icon: Icons.computer,
          searchTerm: "Technology",
          genreId: "1318"),
    ],
  ),
  ThemeCategory(
    name: "Loisirs",
    icon: Icons.sports_esports,
    description: "Divertissement, arts et temps libre.",
    subThemes: [
      SubTheme(
          name: "Arts",
          icon: Icons.palette,
          searchTerm: "Arts",
          genreId: "1301"),
      SubTheme(
          name: "Humour",
          icon: Icons.sentiment_very_satisfied,
          searchTerm: "Comedy",
          genreId: "1303"),
      SubTheme(
          name: "Loisirs",
          icon: Icons.videogame_asset,
          searchTerm: "Leisure",
          genreId: "1502"),
      SubTheme(
          name: "Musique",
          icon: Icons.music_note,
          searchTerm: "Music",
          genreId: "1310"),
      SubTheme(
          name: "Romans et nouvelles",
          icon: Icons.menu_book,
          searchTerm: "Fiction",
          genreId: "1483"),
      SubTheme(
          name: "Télévision et cinéma",
          icon: Icons.movie,
          searchTerm: "TV & Film",
          genreId: "1309"),
    ],
  ),
  ThemeCategory(
    name: "Savoirs",
    icon: Icons.school,
    description: "Apprentissage, éducation et sciences.",
    subThemes: [
      SubTheme(
          name: "Éducation",
          icon: Icons.menu_book,
          searchTerm: "Education",
          genreId: "1304"),
      SubTheme(
          name: "Sciences",
          icon: Icons.science,
          searchTerm: "Science",
          genreId: "1533"),
    ],
  ),
  ThemeCategory(
    name: "Société",
    icon: Icons.policy,
    description: "Comprendre la société à travers ses histoires et ses débats.",
    subThemes: [
      SubTheme(
          name: "Criminologie",
          icon: Icons.local_police,
          searchTerm: "True Crime",
          genreId: "1488"),
      SubTheme(
          name: "Culture et société",
          icon: Icons.groups,
          searchTerm: "Society & Culture",
          genreId: "1324"),
      SubTheme(
          name: "Histoire",
          icon: Icons.history_edu,
          searchTerm: "History",
          genreId: "1487"),
      SubTheme(
          name: "Religion et spiritualité",
          icon: Icons.self_improvement,
          searchTerm: "Religion & Spirituality",
          genreId: "1314"),
    ],
  ),
  ThemeCategory(
    name: "Vie Pratique",
    icon: Icons.favorite,
    description: "Forme, santé, sport et vie de famille.",
    subThemes: [
      SubTheme(
          name: "Enfants et parents",
          icon: Icons.family_restroom,
          searchTerm: "Kids & Family",
          genreId: "1305"),
      SubTheme(
          name: "Forme et santé",
          icon: Icons.health_and_safety,
          searchTerm: "Health & Fitness",
          genreId: "1512"),
      SubTheme(
          name: "Sports",
          icon: Icons.sports_soccer,
          searchTerm: "Sports",
          genreId: "1545"),
    ],
  ),
];

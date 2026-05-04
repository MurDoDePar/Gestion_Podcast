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
  final String description;

  const SubTheme({
    required this.name,
    required this.icon,
    required this.description,
  });
}

const List<ThemeCategory> themesList = [
  ThemeCategory(
    name: "Culture & Arts",
    icon: Icons.palette,
    description: "Découvrez le meilleur de la création culturelle et artistique.",
    subThemes: [
      SubTheme(name: "Cinéma & Séries", icon: Icons.movie, description: "Analyse de films, séries et interviews."),
      SubTheme(name: "Littérature & BD", icon: Icons.menu_book, description: "Classiques, romans et bandes dessinées."),
      SubTheme(name: "Musique & Radio", icon: Icons.music_note, description: "Histoire musicale, genres et radio."),
      SubTheme(name: "Histoire & Patrimoine", icon: Icons.history_edu, description: "Exploration du passé et du patrimoine."),
      SubTheme(name: "Humour & Stand-up", icon: Icons.sentiment_very_satisfied, description: "Stand-up, comédie et divertissement."),
    ],
  ),
  ThemeCategory(
    name: "Société & Récits",
    icon: Icons.policy,
    description: "Comprendre la société à travers ses histoires et ses débats.",
    subThemes: [
      SubTheme(name: "Affaires Criminelles", icon: Icons.gavel, description: "Crimes, enquêtes et true crime."),
      SubTheme(name: "Témoignages & Vie", icon: Icons.record_voice_over, description: "Parcours de vie et récits intimes."),
      SubTheme(name: "Grandes Enquêtes", icon: Icons.newspaper, description: "Investigations et journalisme de fond."),
      SubTheme(name: "Politique & Médias", icon: Icons.campaign, description: "Analyse politique et décryptage média."),
      SubTheme(name: "Mystères & Paranormal", icon: Icons.help_outline, description: "Phénomènes inexpliqués et mystères."),
    ],
  ),
  ThemeCategory(
    name: "Business & Tech",
    icon: Icons.business_center,
    description: "Les enjeux économiques et les innovations technologiques.",
    subThemes: [
      SubTheme(name: "Entrepreneuriat", icon: Icons.lightbulb, description: "Création d'entreprise et leadership."),
      SubTheme(name: "Finance & Économie", icon: Icons.attach_money, description: "Marchés, investissement et économie."),
      SubTheme(name: "Intelligence Artificielle", icon: Icons.smart_toy, description: "IA, algorithmes et technologies futures."),
      SubTheme(name: "Culture Numérique", icon: Icons.devices, description: "Impact du web et des réseaux sociaux."),
      SubTheme(name: "Innovations & Futur", icon: Icons.rocket_launch, description: "Prospective et nouvelles tendances."),
    ],
  ),
  ThemeCategory(
    name: "Savoirs & Vie",
    icon: Icons.science,
    description: "Apprendre, comprendre et mieux vivre au quotidien.",
    subThemes: [
      SubTheme(name: "Psychologie & Mental", icon: Icons.psychology, description: "Fonctionnement de l'esprit et bien-être."),
      SubTheme(name: "Santé & Nutrition", icon: Icons.health_and_safety, description: "Médecine, alimentation et forme."),
      SubTheme(name: "Écologie & Nature", icon: Icons.eco, description: "Environnement, faune et flore."),
      SubTheme(name: "Parentalité & Famille", icon: Icons.family_restroom, description: "Éducation, enfants et vie de famille."),
      SubTheme(name: "Vulgarisation Scientifique", icon: Icons.school, description: "Sciences accessibles à tous."),
    ],
  ),
  ThemeCategory(
    name: "Loisirs & Action",
    icon: Icons.sports_esports,
    description: "Le monde du sport, des passions et du divertissement.",
    subThemes: [
      SubTheme(name: "Football & Collectifs", icon: Icons.sports_soccer, description: "Football, basket et sports d'équipe."),
      SubTheme(name: "Sports Individuels", icon: Icons.sports_martial_arts, description: "Athlétisme, natation et sports solo."),
      SubTheme(name: "Gastronomie & Vin", icon: Icons.restaurant, description: "Cuisine, chefs et œnologie."),
      SubTheme(name: "Voyage & Aventure", icon: Icons.flight, description: "Exploration, carnets de voyage et évasion."),
      SubTheme(name: "Jeux Vidéo & Geek", icon: Icons.sports_esports, description: "Gaming, pop culture et tech ludique."),
    ],
  ),
];

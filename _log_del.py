import os
import sys
import argparse
import tempfile
import re
import subprocess
from pathlib import Path

# Couleurs ANSI pour la console
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    RESET = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# Activation du mode virtuel terminal sur Windows pour les couleurs ANSI
if os.name == 'nt':
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except Exception:
        pass

def format_size(size_bytes):
    """Formate une taille en octets de manière lisible."""
    for unit in ['o', 'Ko', 'Mo', 'Go']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.2f} To"

def parse_arguments():
    parser = argparse.ArgumentParser(description="Nettoyage des fichiers de logs et des logs dans le code (logcat) pour PodStream.")
    parser.add_argument(
        '-d', '--dry-run',
        action='store_true',
        help="Simuler les actions sans modifier les fichiers ni supprimer réellement."
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help="Afficher le détail de chaque fichier traité."
    )
    parser.add_argument(
        '--no-files',
        action='store_true',
        help="Ne pas supprimer les fichiers .log physiques."
    )
    parser.add_argument(
        '--no-code',
        action='store_true',
        help="Ne pas commenter les instructions print/debugPrint dans le code source Dart."
    )
    parser.add_argument(
        '--no-logcat-clear',
        action='store_true',
        help="Ne pas vider le tampon logcat du téléphone via ADB."
    )
    return parser.parse_args()

def comment_logs_in_code(project_dir, dry_run, verbose):
    """Commente les instructions print() et debugPrint() dans le code source Dart."""
    lib_dir = project_dir / "podcast_app" / "lib"
    if not lib_dir.exists():
        print(f"{Colors.YELLOW}[ATTENTION] Dossier lib introuvable à l'emplacement : {lib_dir}{Colors.RESET}\n")
        return 0, 0

    print(f"{Colors.BOLD}3. Commentaire des logs (print/debugPrint) dans le code source Dart : {lib_dir}{Colors.RESET}")
    
    modified_files_count = 0
    total_commented_lines = 0
    
    # Regex pour trouver print( ou debugPrint( non commentés
    # On évite de faire correspondre si c'est déjà commenté par // ou * (dans un bloc de commentaire)
    log_pattern = re.compile(r'\b(print|debugPrint)\s*\(')

    for root, dirs, files in os.walk(lib_dir):
        # Exclure le dossier de code généré Data Connect
        if "dataconnect-generated" in root:
            continue
            
        for file in files:
            if file.endswith('.dart'):
                file_path = Path(root) / file
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                    
                    modified = False
                    commented_in_file = 0
                    in_log_statement = False
                    
                    for i, line in enumerate(lines):
                        stripped = line.strip()
                        
                        if not in_log_statement:
                            # Recherche d'une instruction active de log
                            if log_pattern.search(line) and not stripped.startswith("//") and not stripped.startswith("*") and not stripped.startswith("/*"):
                                in_log_statement = True
                                lines[i] = f"// {line}"
                                commented_in_file += 1
                                modified = True
                                
                                # Si l'instruction se termine sur la même ligne
                                if ");" in line:
                                    in_log_statement = False
                        else:
                            # Commenter la suite de l'instruction multi-ligne
                            lines[i] = f"// {line}"
                            commented_in_file += 1
                            modified = True
                            
                            if ");" in line:
                                in_log_statement = False
                    
                    if modified:
                        modified_files_count += 1
                        total_commented_lines += commented_in_file
                        
                        rel_path = file_path.relative_to(project_dir)
                        action_label = f"{Colors.YELLOW}[SIMULATION]{Colors.RESET} " if dry_run else ""
                        if verbose or not dry_run:
                            print(f"   - {action_label}Modifié: {rel_path} ({commented_in_file} lignes commentées)")
                            
                        if not dry_run:
                            with open(file_path, 'w', encoding='utf-8') as f:
                                f.writelines(lines)
                except Exception as e:
                    print(f"   {Colors.RED}[ERREUR] Impossible de lire/écrire le fichier {file}: {e}{Colors.RESET}")
                    
    if modified_files_count == 0:
        print("   Aucun log actif à commenter dans le code Dart.\n")
    else:
        print(f"   Total : {modified_files_count} fichiers modifiés, {total_commented_lines} lignes de logs commentées.\n")
        
    return modified_files_count, total_commented_lines

def clear_adb_logcat(dry_run):
    """Vide le tampon de logcat du téléphone connecté."""
    print(f"{Colors.BOLD}4. Vidage du tampon de logs logcat sur le téléphone connecté...{Colors.RESET}")
    
    if dry_run:
        print(f"   {Colors.YELLOW}[SIMULATION] adb logcat -c aurait été exécuté.{Colors.RESET}\n")
        return True
        
    try:
        # Tenter d'exécuter adb logcat -c
        result = subprocess.run(
            ["adb", "logcat", "-c"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            print(f"   {Colors.GREEN}[SUCCÈS] logcat vidé avec succès sur le téléphone.{Colors.RESET}\n")
            return True
        else:
            print(f"   {Colors.YELLOW}[INFO] ADB a répondu avec une erreur (aucun appareil connecté ?).{Colors.RESET}\n")
            return False
    except FileNotFoundError:
        print(f"   {Colors.YELLOW}[INFO] Commande 'adb' introuvable dans le PATH du système.{Colors.RESET}\n")
        return False
    except subprocess.TimeoutExpired:
        print(f"   {Colors.YELLOW}[INFO] La commande adb a expiré.{Colors.RESET}\n")
        return False
    except Exception as e:
        print(f"   {Colors.YELLOW}[INFO] Erreur lors de l'exécution de adb logcat : {e}{Colors.RESET}\n")
        return False

def clean_logs():
    args = parse_arguments()
    
    project_dir = Path(__file__).resolve().parent
    temp_dir = Path(tempfile.gettempdir())
    
    # Dossiers à ignorer pour la recherche de fichiers logs physiques
    ignored_dirs = {
        '.git',
        'node_modules',
        '.dart_tool',
        'build',
        '.gradle',
        '.idea',
        '.vscode'
    }
    
    deleted_files_count = 0
    error_files_count = 0
    total_size_freed = 0
    
    action_label = f"{Colors.YELLOW}[SIMULATION]{Colors.RESET} " if args.dry_run else ""
    
    print(f"{Colors.BOLD}{Colors.BLUE}=================================================={Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}   NETTOYAGE ET PURGE DES LOGS (PodStream){Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}=================================================={Colors.RESET}\n")
    
    if args.dry_run:
        print(f"{Colors.YELLOW}Mode Simulation activé. Aucune modification réelle ne sera effectuée.{Colors.RESET}\n")
        
    # Phase 1 : Fichiers .log du projet
    if not args.no_files:
        print(f"{Colors.BOLD}1. Recherche des fichiers .log dans le projet : {project_dir}{Colors.RESET}")
        
        log_files_project = []
        for root, dirs, files in os.walk(project_dir):
            dirs[:] = [d for d in dirs if d not in ignored_dirs]
            for file in files:
                if file.endswith('.log'):
                    log_files_project.append(Path(root) / file)

        if not log_files_project:
            print("   Aucun fichier .log trouvé dans les dossiers du projet.\n")
        else:
            for file_path in log_files_project:
                try:
                    size = file_path.stat().st_size
                    total_size_freed += size
                    rel_path = file_path.relative_to(project_dir)
                    
                    if args.verbose or not args.dry_run:
                        print(f"   - {action_label}Projet: {rel_path} ({format_size(size)})")
                    
                    if not args.dry_run:
                        file_path.unlink()
                    
                    deleted_files_count += 1
                except Exception as e:
                    print(f"   {Colors.RED}[ERREUR] Impossible d'accéder/supprimer {file_path.name}: {e}{Colors.RESET}")
                    error_files_count += 1
            print()

        # Phase 2 : Fichiers logs temporaires du système (podstream_*.log)
        print(f"{Colors.BOLD}2. Recherche des fichiers temporaires (podstream_*.log) dans : {temp_dir}{Colors.RESET}")
        
        log_files_temp = []
        try:
            for item in temp_dir.glob("podstream_*.log"):
                if item.is_file():
                    log_files_temp.append(item)
            for item in temp_dir.glob("firebase-debug*.log"):
                if item.is_file():
                    log_files_temp.append(item)
        except Exception as e:
            print(f"   {Colors.RED}[ERREUR] Impossible de lister le dossier temporaire : {e}{Colors.RESET}")
            
        if not log_files_temp:
            print("   Aucun fichier log temporaire podstream_ trouvé.\n")
        else:
            for file_path in log_files_temp:
                try:
                    size = file_path.stat().st_size
                    total_size_freed += size
                    
                    if args.verbose or not args.dry_run:
                        print(f"   - {action_label}Temp: {file_path.name} ({format_size(size)})")
                    
                    if not args.dry_run:
                        file_path.unlink()
                    
                    deleted_files_count += 1
                except Exception as e:
                    if args.verbose:
                        print(f"   {Colors.YELLOW}[VERROUILLÉ] {file_path.name} (en cours d'utilisation){Colors.RESET}")
                    error_files_count += 1
            print()

    # Phase 3 : Commenter les logs dans le code source
    modified_files_count = 0
    total_commented_lines = 0
    if not args.no_code:
        modified_files_count, total_commented_lines = comment_logs_in_code(project_dir, args.dry_run, args.verbose)
        
    # Phase 4 : Vider logcat
    if not args.no_logcat_clear:
        clear_adb_logcat(args.dry_run)

    # Résumé final
    print(f"{Colors.BOLD}{Colors.BLUE}=================================================={Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}   RÉSUMÉ DU NETTOYAGE{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}=================================================={Colors.RESET}")
    
    if args.dry_run:
        if not args.no_files:
            print(f"Fichiers logs identifiés : {Colors.GREEN}{deleted_files_count}{Colors.RESET}")
            print(f"Espace estimé libérable : {Colors.GREEN}{format_size(total_size_freed)}{Colors.RESET}")
        if not args.no_code:
            print(f"Fichiers code à modifier : {Colors.GREEN}{modified_files_count}{Colors.RESET} ({total_commented_lines} lignes de logs)")
    else:
        if not args.no_files:
            print(f"Fichiers logs supprimés : {Colors.GREEN}{deleted_files_count}{Colors.RESET}")
            print(f"Espace total libéré : {Colors.GREEN}{format_size(total_size_freed)}{Colors.RESET}")
        if not args.no_code:
            print(f"Fichiers code modifiés : {Colors.GREEN}{modified_files_count}{Colors.RESET} ({total_commented_lines} lignes de logs commentées)")
            
    if error_files_count > 0:
        print(f"Fichiers logs inaccessibles/verrouillés : {Colors.YELLOW}{error_files_count}{Colors.RESET}")
        
    print(f"{Colors.BOLD}{Colors.BLUE}=================================================={Colors.RESET}\n")

if __name__ == '__main__':
    clean_logs()

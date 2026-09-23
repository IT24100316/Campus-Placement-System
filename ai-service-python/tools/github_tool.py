import re
import requests
import asyncio

async def analyze_github_profile(cv_text: str) -> str:
    """
    Extracts GitHub username from CV, calls GitHub API, 
    and deeply analyzes the quality and authenticity of the repos.
    """
    # 1. Extract username
    match = re.search(r"github\.com/([a-zA-Z0-9-]+)", cv_text, re.IGNORECASE)
    if not match:
        return "No GitHub profile found in CV."
    
    username = match.group(1)
    
    # 2. Call GitHub API for Repositories
    url = f"https://api.github.com/users/{username}/repos?per_page=100&sort=pushed"
    headers = {"Accept": "application/vnd.github.v3+json"}
    
    try:
        response = await asyncio.to_thread(requests.get, url, headers=headers, timeout=15)
        
        if response.status_code == 404:
            return f"GitHub profile '{username}' found in CV, but does not exist."
        if response.status_code == 403:
            return f"GitHub rate limit exceeded. Could not fetch data."
        if response.status_code != 200:
            return f"Could not fetch GitHub data (Status: {response.status_code})."
            
        repos = response.json()
        if not isinstance(repos, list):
            return "Unexpected response from GitHub."
            
        # 3. Filter original repos
        original_repos = [repo for repo in repos if not repo.get("fork")]
        
        if not original_repos:
            return f"Profile '{username}' has {len(repos)} repos, but all are forks. No original code."
            
        # Extract Languages & Setup Analytics
        languages = {}
        repo_summaries = []
        
        # Take the top 5 most recently active original repos for a Deep Dive
        top_repos = original_repos[:5]
        
        for repo in top_repos:
            name = repo.get("name", "Unknown")
            desc = repo.get("description") or "No description provided"
            lang = repo.get("language") or "Unknown Language"
            topics = repo.get("topics", [])
            stars = repo.get("stargazers_count", 0)
            
            if lang != "Unknown Language":
                languages[lang] = languages.get(lang, 0) + 1
                
            # --- DEEP DIVE 1: Check Commits (Red Flag Check) ---
            # We fetch max 2 commits. If length is 1, it was uploaded in a single day!
            commits_url = repo.get("commits_url", "").replace("{/sha}", "?per_page=2")
            commit_res = await asyncio.to_thread(requests.get, commits_url, headers=headers)
            
            commit_status = "Unknown"
            if commit_res.status_code == 200:
                commits_data = commit_res.json()
                if len(commits_data) == 1:
                    commit_status = "⚠️ RED FLAG: Single commit upload (Possible copy-paste)"
                else:
                    commit_status = "✅ Iterative commits (Genuine development)"

            # --- DEEP DIVE 2: Check README (Documentation Quality) ---
            readme_url = f"https://api.github.com/repos/{username}/{name}/readme"
            readme_res = await asyncio.to_thread(requests.get, readme_url, headers=headers)
            readme_status = "✅ Good documentation" if readme_res.status_code == 200 else "❌ Missing README"
            
            # Format the insights for this repo
            topics_str = f" | Tags: {', '.join(topics)}" if topics else ""
            repo_summaries.append(
                f"- Project: '{name}' ({lang})\n"
                f"  Details: {desc}{topics_str}\n"
                f"  Quality checks -> Docs: {readme_status} | Commits: {commit_status} | Stars: {stars}\n"
            )

        # Count languages for the rest of the repos
        for repo in original_repos[5:]:
            lang = repo.get("language")
            if lang:
                languages[lang] = languages.get(lang, 0) + 1
                
        # Sort languages
        top_languages = sorted(languages.items(), key=lambda x: x[1], reverse=True)
        lang_str = ", ".join([f"{l} ({c} repos)" for l, c in top_languages[:4]])
        
        # 4. Final Aggregated Output for AI
        final_summary = (
            f"GitHub Analysis for '{username}':\n"
            f"Total Original Repositories: {len(original_repos)}\n"
            f"Top Tech Stack: {lang_str}\n\n"
            f"--- Deep Inspection of Top 5 Recent Projects ---\n"
            + "\n".join(repo_summaries)
        )
        
        return final_summary

    except Exception as e:
        return f"Error deeply analyzing GitHub profile: {str(e)}"
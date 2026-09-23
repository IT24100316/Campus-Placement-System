-- SkillEquivalences: the lookup table your Analysis Agent checks BEFORE
-- calling the LLM. Run once in Supabase SQL editor.
--
-- Fields:
--   TermA / TermB   normalized (lowercase, trimmed) skill names, always
--                   stored in alphabetical order so a lookup for either
--                   direction hits the same row
--   IsMatch         true = same skill, different name. false = confirmed
--                   NOT equivalent (prevents the LLM being asked again)
--   Reason          short justification, shown in skill_breakdown for
--                   explainability
--   Source          'seed' (this file) or 'llm' (written by the agent
--                   at runtime when it resolves a genuinely new pair)
--   CreatedAt       when the row was added

INSERT INTO "SkillEquivalences" ("TermA", "TermB", "IsMatch", "Reason", "Source") VALUES

-- ===== .NET / C# =====
('c#', '.net', true, 'C# is the primary language of the .NET ecosystem', 'seed'),
('csharp', 'c#', true, 'Alternate spelling', 'seed'),
('dotnet', '.net', true, 'Same technology, alternate spelling', 'seed'),
('asp.net', '.net', true, 'ASP.NET is the web framework within .NET', 'seed'),
('aspnet', 'asp.net', true, 'Alternate spelling', 'seed'),
('asp.net core', 'asp.net', true, 'ASP.NET Core is the current version of ASP.NET', 'seed'),
('ef core', 'entity framework', true, 'EF Core is the current version of Entity Framework', 'seed'),
('efcore', 'ef core', true, 'Alternate spelling', 'seed'),
('blazor', '.net', false, 'Blazor is a specific UI framework within .NET, not interchangeable with general .NET skill', 'seed'),
('vb.net', '.net', false, 'VB.NET is a different language on the .NET platform than C#', 'seed'),

-- ===== JavaScript / TypeScript ecosystem =====
('js', 'javascript', true, 'Common abbreviation', 'seed'),
('ts', 'typescript', true, 'Common abbreviation', 'seed'),
('reactjs', 'react', true, 'Same library, alternate naming', 'seed'),
('react.js', 'react', true, 'Same library, alternate naming', 'seed'),
('nodejs', 'node', true, 'Same technology, alternate naming', 'seed'),
('node.js', 'node', true, 'Same technology, alternate naming', 'seed'),
('vuejs', 'vue', true, 'Same framework, alternate naming', 'seed'),
('vue.js', 'vue', true, 'Same framework, alternate naming', 'seed'),
('nextjs', 'next.js', true, 'Alternate spelling', 'seed'),
('nuxtjs', 'nuxt.js', true, 'Alternate spelling', 'seed'),
('expressjs', 'express', true, 'Same framework, alternate naming', 'seed'),
('express.js', 'express', true, 'Same framework, alternate naming', 'seed'),
('angularjs', 'angular', false, 'AngularJS (v1) and Angular (v2+) are different, largely incompatible frameworks', 'seed'),
('jquery', 'javascript', false, 'jQuery is a specific library, not interchangeable with general JavaScript skill', 'seed'),
('redux', 'react', false, 'Redux is a state management library, distinct skill from React itself', 'seed'),
('sass', 'css', false, 'Sass is a CSS preprocessor, related but a distinct skill from plain CSS', 'seed'),
('scss', 'sass', true, 'SCSS is a syntax variant of Sass', 'seed'),
('tailwindcss', 'tailwind', true, 'Alternate naming', 'seed'),

-- ===== Python ecosystem =====
('py', 'python', true, 'Common abbreviation', 'seed'),
('django rest framework', 'drf', true, 'Common abbreviation', 'seed'),
('flask', 'django', false, 'Both are Python web frameworks but distinct skills, not interchangeable', 'seed'),
('fastapi', 'flask', false, 'Both are Python web frameworks but distinct skills, not interchangeable', 'seed'),
('numpy', 'pandas', false, 'Both are Python data libraries but serve different purposes, not interchangeable', 'seed'),

-- ===== Java / JVM =====
('java', 'javascript', false, 'Despite the similar name, Java and JavaScript are unrelated languages', 'seed'),
('spring boot', 'spring', true, 'Spring Boot is the current standard way to build Spring applications', 'seed'),
('springboot', 'spring boot', true, 'Alternate spelling', 'seed'),
('kotlin', 'java', false, 'Different languages, though both run on the JVM', 'seed'),

-- ===== Databases =====
('postgres', 'postgresql', true, 'Common abbreviation', 'seed'),
('psql', 'postgresql', true, 'Common abbreviation', 'seed'),
('mongo', 'mongodb', true, 'Common abbreviation', 'seed'),
('mysql', 'sql', false, 'MySQL is one specific SQL database, not interchangeable with a generic SQL skill claim', 'seed'),
('postgresql', 'sql', false, 'PostgreSQL is one specific SQL database, not interchangeable with a generic SQL skill claim', 'seed'),
('mssql', 'sql server', true, 'Common abbreviation for Microsoft SQL Server', 'seed'),
('sql server', 'sql', false, 'SQL Server is one specific database, not interchangeable with generic SQL skill', 'seed'),
('nosql', 'mongodb', false, 'NoSQL is a broad category; MongoDB is one specific implementation', 'seed'),
('redis', 'sql', false, 'Redis is a NoSQL key-value store, unrelated to SQL skills', 'seed'),
('sqlite', 'sql', false, 'SQLite is one specific database engine, not interchangeable with generic SQL skill', 'seed'),

-- ===== Cloud / DevOps =====
('aws', 'amazon web services', true, 'Standard abbreviation', 'seed'),
('gcp', 'google cloud platform', true, 'Standard abbreviation', 'seed'),
('azure', 'microsoft azure', true, 'Standard abbreviation', 'seed'),
('k8s', 'kubernetes', true, 'Standard abbreviation', 'seed'),
('ci/cd', 'continuous integration', true, 'CI/CD includes continuous integration', 'seed'),
('docker compose', 'docker', true, 'Docker Compose is part of the Docker toolchain', 'seed'),
('terraform', 'aws', false, 'Terraform is an IaC tool, not specific to or interchangeable with AWS skill', 'seed'),
('github actions', 'ci/cd', true, 'GitHub Actions is a CI/CD implementation', 'seed'),
('jenkins', 'ci/cd', true, 'Jenkins is a CI/CD implementation', 'seed'),
('ansible', 'terraform', false, 'Both are IaC/automation tools but serve different purposes, not interchangeable', 'seed'),

-- ===== Mobile =====
('rn', 'react native', true, 'Common abbreviation', 'seed'),
('flutter', 'dart', false, 'Flutter is a framework, Dart is the language it uses — related but not the same skill', 'seed'),
('swift', 'swiftui', false, 'Swift is the language, SwiftUI is a specific UI framework — related but distinct', 'seed'),
('kotlin', 'android', false, 'Kotlin is a language, Android is a platform — related but not interchangeable', 'seed'),
('java', 'android', false, 'Java is a language, Android is a platform — related but not interchangeable', 'seed'),

-- ===== Data / AI / ML =====
('ml', 'machine learning', true, 'Standard abbreviation', 'seed'),
('dl', 'deep learning', true, 'Standard abbreviation', 'seed'),
('nlp', 'natural language processing', true, 'Standard abbreviation', 'seed'),
('cv', 'computer vision', true, 'Standard abbreviation (in an ML/AI context)', 'seed'),
('pd', 'pandas', true, 'Common abbreviation', 'seed'),
('tensorflow', 'pytorch', false, 'Both are deep learning frameworks but distinct skills, not interchangeable', 'seed'),
('scikit-learn', 'sklearn', true, 'Alternate naming for the same library', 'seed'),
('llm', 'machine learning', false, 'LLM/generative AI is a specific subfield, not interchangeable with general ML skill', 'seed'),
('power bi', 'tableau', false, 'Both are BI/visualization tools but distinct skills, not interchangeable', 'seed'),

-- ===== Testing =====
('unit testing', 'testing', true, 'Unit testing is a core part of general software testing skill', 'seed'),
('jest', 'unit testing', true, 'Jest is a JavaScript unit testing framework', 'seed'),
('xunit', 'unit testing', true, 'xUnit is a .NET unit testing framework', 'seed'),
('nunit', 'unit testing', true, 'NUnit is a .NET unit testing framework', 'seed'),
('selenium', 'testing', true, 'Selenium is a browser automation/testing tool', 'seed'),
('cypress', 'selenium', false, 'Both are testing tools but different frameworks/approaches, not interchangeable', 'seed'),

-- ===== General / cross-cutting =====
('oop', 'object oriented programming', true, 'Standard abbreviation', 'seed'),
('api', 'rest api', false, 'API is a broad term, REST API is one specific style — not interchangeable as a skill claim', 'seed'),
('restful api', 'rest api', true, 'Alternate naming', 'seed'),
('graphql', 'rest api', false, 'GraphQL and REST are different API paradigms, not interchangeable', 'seed'),
('git', 'github', false, 'Git is the version control system, GitHub is a hosting platform for it — related but distinct', 'seed'),
('agile', 'scrum', false, 'Agile is a broad methodology; Scrum is one specific framework within it', 'seed'),

-- ===== Frontend =====
('ui/ux', 'ui', false, 'UI/UX includes UX which is a distinct skill from UI alone', 'seed'),
('figma', 'ui/ux', true, 'Figma is a design tool used for UI/UX work', 'seed'),
('adobe xd', 'figma', false, 'Both are design tools but distinct products, not interchangeable', 'seed'),
('html5', 'html', true, 'HTML5 is the current standard version of HTML', 'seed'),
('css3', 'css', true, 'CSS3 is the current standard version of CSS', 'seed'),
('responsive design', 'css', false, 'Responsive design is a broader skill/approach, not interchangeable with raw CSS knowledge', 'seed'),
('bootstrap', 'css', false, 'Bootstrap is a specific CSS framework, not interchangeable with general CSS skill', 'seed'),
('webpack', 'frontend build tools', true, 'Webpack is a frontend bundling/build tool', 'seed'),
('vite', 'webpack', false, 'Both are frontend build tools but distinct products, not interchangeable', 'seed'),
('spa', 'single page application', true, 'Standard abbreviation', 'seed'),
('pwa', 'progressive web app', true, 'Standard abbreviation', 'seed'),

-- ===== Backend =====
('backend development', 'server-side development', true, 'Same meaning, alternate phrasing', 'seed'),
('microservices', 'monolithic architecture', false, 'Opposite architectural approaches, not interchangeable', 'seed'),
('grpc', 'rest api', false, 'gRPC and REST are different API/communication paradigms, not interchangeable', 'seed'),
('websocket', 'rest api', false, 'WebSocket is a different communication protocol (real-time/bidirectional) than REST', 'seed'),
('message queue', 'rabbitmq', true, 'RabbitMQ is a common message queue implementation', 'seed'),
('kafka', 'rabbitmq', false, 'Both are messaging systems but distinct technologies with different use cases', 'seed'),
('orm', 'entity framework', false, 'ORM is a broad concept/category; Entity Framework is one specific implementation', 'seed'),
('serverless', 'aws lambda', false, 'Serverless is a broad architecture pattern; AWS Lambda is one specific implementation', 'seed'),

-- ===== Cybersecurity =====
('infosec', 'cybersecurity', true, 'Common abbreviation', 'seed'),
('cyber security', 'cybersecurity', true, 'Alternate spelling', 'seed'),
('penetration testing', 'pentest', true, 'Common abbreviation', 'seed'),
('pentesting', 'penetration testing', true, 'Alternate spelling', 'seed'),
('ethical hacking', 'penetration testing', true, 'Common alternate naming for the same practice', 'seed'),
('owasp', 'web security', true, 'OWASP is a widely-referenced web application security standard/body', 'seed'),
('siem', 'security monitoring', true, 'SIEM tools are used for security monitoring', 'seed'),
('vapt', 'vulnerability assessment', true, 'VAPT (Vulnerability Assessment and Penetration Testing) includes vulnerability assessment', 'seed'),
('vapt', 'penetration testing', false, 'VAPT includes penetration testing but is broader (also includes vulnerability assessment) — not fully interchangeable', 'seed'),
('firewall', 'network security', true, 'Firewalls are a core network security tool/skill', 'seed'),
('cryptography', 'encryption', true, 'Encryption is a core part of cryptography', 'seed'),
('iam', 'identity and access management', true, 'Standard abbreviation', 'seed'),
('soc analyst', 'security operations', true, 'SOC (Security Operations Center) analyst role centers on security operations', 'seed'),
('burp suite', 'penetration testing', true, 'Burp Suite is a tool commonly used for penetration testing', 'seed'),
('nmap', 'network security', true, 'Nmap is a network scanning tool used in network security work', 'seed'),
('ceh', 'ethical hacking', true, 'CEH (Certified Ethical Hacker) is a certification in ethical hacking', 'seed'),

-- ===== Data Structures & Algorithms =====
('dsa', 'data structures and algorithms', true, 'Standard abbreviation', 'seed'),
('data structures', 'dsa', false, 'Data structures alone is one half of DSA — algorithms knowledge is a distinct additional skill', 'seed'),
('algorithms', 'dsa', false, 'Algorithms alone is one half of DSA — data structures knowledge is a distinct additional skill', 'seed'),
('big o notation', 'algorithm complexity analysis', true, 'Big O notation is the standard way to express algorithm complexity analysis', 'seed'),
('competitive programming', 'dsa', false, 'Competitive programming applies DSA under contest conditions — a related but distinct additional skill (speed, problem patterns)', 'seed'),
('leetcode', 'competitive programming', false, 'LeetCode is a practice platform, not itself proof of competitive programming experience (e.g. live contests)', 'seed'),
('graph algorithms', 'dsa', false, 'Graph algorithms are a specific topic within DSA, not the whole subject', 'seed'),
('dynamic programming', 'dsa', false, 'Dynamic programming is a specific technique within DSA, not the whole subject', 'seed'),
('system design', 'dsa', false, 'System design (architecture-level) is a distinct skill from DSA (algorithm/data-structure-level)', 'seed'),
('low level design', 'lld', true, 'Standard abbreviation', 'seed'),
('high level design', 'hld', true, 'Standard abbreviation', 'seed')

ON CONFLICT ("TermA", "TermB") DO NOTHING;

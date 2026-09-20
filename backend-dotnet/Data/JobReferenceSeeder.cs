using backend_dotnet.Models;
using Microsoft.EntityFrameworkCore;

namespace backend_dotnet.Data;

public static class JobReferenceSeeder
{
    public static async Task SeedAsync(AppDbContext context)
    {
        // 20 Computing & IT Target Domains and realistic Internship Job Titles
        var domainData = new Dictionary<string, (string Description, string[] Titles)>
        {
            {
                "Software Engineering",
                (
                    "Design, construct, and maintain scalable software systems, backend microservices, and applications.",
                    new[]
                    {
                        "Software Engineer Intern",
                        "Backend Developer Intern",
                        "Frontend Developer Intern",
                        "Full Stack Developer Intern",
                        "Systems Software Engineer Intern"
                    }
                )
            },
            {
                "Web Development",
                (
                    "Building responsive web applications, modern frontends, APIs, and client-facing digital experiences.",
                    new[]
                    {
                        "Web Developer Intern",
                        "Frontend Web Developer Intern",
                        "Full Stack Web Developer Intern",
                        "Web Applications Intern"
                    }
                )
            },
            {
                "Mobile Application Development",
                (
                    "Engineering native and cross-platform mobile apps for iOS and Android.",
                    new[]
                    {
                        "Mobile Application Developer Intern",
                        "Android Developer Intern",
                        "iOS Developer Intern",
                        "Flutter Developer Intern",
                        "React Native Developer Intern"
                    }
                )
            },
            {
                "Artificial Intelligence & Machine Learning",
                (
                    "Developing neural architectures, LLM workflows, predictive models, and intelligent agent systems.",
                    new[]
                    {
                        "AI Engineer Intern",
                        "Machine Learning Engineer Intern",
                        "NLP Engineer Intern",
                        "Computer Vision Engineer Intern",
                        "Generative AI Engineer Intern"
                    }
                )
            },
            {
                "Data Science & Analytics",
                (
                    "Statistical analysis, exploratory data science, forecasting, and business intelligence dashboards.",
                    new[]
                    {
                        "Data Scientist Intern",
                        "Data Analyst Intern",
                        "Business Intelligence Analyst Intern",
                        "Quantitative Research Intern"
                    }
                )
            },
            {
                "Data Engineering",
                (
                    "Constructing robust data pipelines, ETL flows, distributed streaming architectures, and data lakes.",
                    new[]
                    {
                        "Data Engineer Intern",
                        "Big Data Engineer Intern",
                        "Data Pipeline Engineer Intern",
                        "ETL Developer Intern"
                    }
                )
            },
            {
                "Database & Data Platforms",
                (
                    "High-performance transactional database architecture, SQL optimization, and platform reliability.",
                    new[]
                    {
                        "Database Administrator (DBA) Intern",
                        "Database Engineer Intern",
                        "SQL Developer Intern",
                        "Data Platform Intern"
                    }
                )
            },
            {
                "Cybersecurity",
                (
                    "Information protection, offensive security, defensive operations, incident response, and compliance.",
                    new[]
                    {
                        "Cybersecurity Engineer Intern",
                        "Information Security Analyst Intern",
                        "SOC Analyst Intern",
                        "Penetration Testing / Ethical Hacker Intern",
                        "Security Operations Intern"
                    }
                )
            },
            {
                "Cloud Computing",
                (
                    "Cloud infrastructure deployment, multi-region elasticity, virtualization, AWS/Azure architectures.",
                    new[]
                    {
                        "Cloud Engineer Intern",
                        "Cloud Solutions Architect Intern",
                        "AWS Cloud Intern",
                        "Azure Cloud Intern"
                    }
                )
            },
            {
                "DevOps & Site Reliability Engineering",
                (
                    "CI/CD pipelines, container orchestration, automated deployments, monitoring, and platform reliability.",
                    new[]
                    {
                        "DevOps Engineer Intern",
                        "Site Reliability Engineer (SRE) Intern",
                        "Platform Engineer Intern",
                        "Build & Release Engineer Intern"
                    }
                )
            },
            {
                "Networking & Infrastructure",
                (
                    "Enterprise network routing, switching, infrastructure administration, firewalls, and protocols.",
                    new[]
                    {
                        "Network Engineer Intern",
                        "Systems Administrator Intern",
                        "Network Security Intern",
                        "Infrastructure Support Engineer Intern"
                    }
                )
            },
            {
                "Embedded Systems & IoT",
                (
                    "Microcontroller programming, firmware development, RTOS, sensor telemetry, and IoT platforms.",
                    new[]
                    {
                        "Embedded Software Engineer Intern",
                        "Firmware Engineer Intern",
                        "IoT Solutions Intern",
                        "Microcontroller Systems Intern"
                    }
                )
            },
            {
                "Robotics",
                (
                    "Autonomous navigation, robotics kinematics, perception systems, sensor fusion, and control logic.",
                    new[]
                    {
                        "Robotics Software Engineer Intern",
                        "Autonomous Systems Intern",
                        "Control Systems Intern"
                    }
                )
            },
            {
                "QA & Software Testing",
                (
                    "Automated test suites, regression testing, QA validation, performance benchmarking, and test planning.",
                    new[]
                    {
                        "QA Engineer Intern",
                        "Software Test Automation Intern",
                        "Manual QA Tester Intern",
                        "Performance & Load Testing Intern"
                    }
                )
            },
            {
                "UI/UX & Product Design",
                (
                    "Design systems, user research, wireframing, high-fidelity prototyping, and usability validation.",
                    new[]
                    {
                        "UI/UX Designer Intern",
                        "Product Designer Intern",
                        "User Experience Researcher Intern",
                        "Visual & Interaction Designer Intern"
                    }
                )
            },
            {
                "Business Analysis",
                (
                    "Requirements gathering, workflow analysis, functional specifications, and technical translation.",
                    new[]
                    {
                        "Business Analyst Intern",
                        "IT Business Systems Analyst Intern",
                        "Functional Consultant Intern"
                    }
                )
            },
            {
                "Product Management",
                (
                    "Product lifecycle ownership, agile roadmap planning, stakeholder alignment, and feature definition.",
                    new[]
                    {
                        "Associate Product Manager Intern",
                        "Technical Product Management Intern",
                        "Product Operations Intern"
                    }
                )
            },
            {
                "Enterprise Applications",
                (
                    "Large-scale enterprise ERP, CRM solutions, integration middlewares, and business workflows.",
                    new[]
                    {
                        "ERP Technical Consultant Intern (SAP/Oracle)",
                        "CRM Solutions Intern (Salesforce/Dynamics)",
                        "Enterprise Solutions Developer Intern"
                    }
                )
            },
            {
                "Computer Systems & Hardware",
                (
                    "Computer architecture, digital logic, FPGA programming, hardware verification, and system benchmarking.",
                    new[]
                    {
                        "Hardware Systems Engineer Intern",
                        "Computer Systems Architect Intern",
                        "FPGA & ASIC Design Intern"
                    }
                )
            },
            {
                "Game Development",
                (
                    "Interactive game engines, gameplay programming, 3D graphics rendering, and physics simulation.",
                    new[]
                    {
                        "Game Developer Intern",
                        "Unity / Unreal Engine Developer Intern",
                        "Gameplay Programmer Intern",
                        "3D Graphics Programmer Intern"
                    }
                )
            }
        };

        // Load existing domains to ensure idempotence
        var existingDomains = await context.TargetDomains
            .Include(d => d.JobTitles)
            .ToListAsync();

        var existingDomainMap = existingDomains.ToDictionary(d => d.Name, StringComparer.OrdinalIgnoreCase);

        bool changesMade = false;

        foreach (var kvp in domainData)
        {
            var domainName = kvp.Key;
            var (description, titles) = kvp.Value;

            if (!existingDomainMap.TryGetValue(domainName, out var domainEntity))
            {
                domainEntity = new TargetDomain
                {
                    Name = domainName,
                    Description = description
                };
                context.TargetDomains.Add(domainEntity);
                changesMade = true;
            }

            // Ensure titles exist for this domain
            var existingTitles = domainEntity.JobTitles
                .Select(t => t.Title)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);

            foreach (var title in titles)
            {
                if (!existingTitles.Contains(title))
                {
                    domainEntity.JobTitles.Add(new JobTitleReference
                    {
                        Title = title,
                        TargetDomain = domainEntity
                    });
                    changesMade = true;
                }
            }
        }

        if (changesMade)
        {
            await context.SaveChangesAsync();
        }
    }
}

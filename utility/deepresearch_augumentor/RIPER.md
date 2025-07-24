The RIPER protocol
Got it. I’ll generate a set of generalized, detailed RIPER protocol prompts specifically designed for a solo developer building any software product, without assuming a fixed timeline. I’ll structure the prompts so they can guide Cursor.ai to act like a smart assistant through the full product lifecycle—from market research to system design to documentation.

I’ll let you know once they’re ready.


# RIPER Framework Prompts for Solo-Developer Product Development

The following prompts guide a code-generation AI assistant (e.g. Cursor.ai) through the full **RIPER** lifecycle (Research, Innovate, Plan, Execute, Review) for any software product. These prompts are tailored for a **solo developer (1-person team)**, emphasizing clarity, efficiency, and modular design. Each prompt can be used at the respective phase of development to generate detailed outputs.

## Research

**Prompt (Research Phase):** *We are beginning a new software product as a solo developer. Conduct a thorough research analysis with the following elements:*

1. **Problem Domain & Opportunity:** Identify and describe the problem domain that the product will address. Clearly define the specific problem or user need we aim to solve, and explain why this problem is important or worthwhile (the opportunity in the market).
2. **Value Proposition:** Articulate the product’s value proposition. Explain what unique value or benefit this product will offer to users, and how it will solve the problem better or differently than existing solutions. Focus on the core advantage that would attract users.
3. **Existing Alternatives Analysis:** Analyze current solutions in this domain (both commercial products and open-source projects). For each major alternative or competitor, briefly describe how it addresses the problem, and note its strengths and weaknesses. Identify gaps or pain points in these existing options that our product could improve upon.
4. **Target Users & Personas:** Define the target audience for this product. Outline 2-3 key user personas or archetypes – who the users are, their goals, technical skill level, and any specific needs or frustrations they have regarding this problem. Emphasize insights that will guide design and features (especially focusing on what a solo-built product can excel at for these users).
5. **Proposed Tech Stack (Solo-Optimized):** Propose a suitable technology stack for building the product as a single developer. Consider **maintainability** and **modern best practices**: for example, choose languages/frameworks that maximize productivity, have strong community support, and are feasible for one person to manage end-to-end. Justify each choice (front-end, back-end, database, hosting, etc.) in terms of ease of development and long-term solo maintenance. (E.g., using one language across the stack for simplicity, choosing a framework that provides a lot out-of-the-box to reduce workload, etc.)

*Focus the output on actionable findings. The research should clarify what we’re building and why, with insights that inform the next steps. Highlight considerations unique to a solo developer environment (limited resources and need for efficiency).*

## Innovate

**Prompt (Innovate Phase):** *Building on the research, let’s brainstorm innovative solutions. We need creative yet feasible ideas for our product.*

1. **Idea Generation (at least 3 ideas):** Propose **three or more** distinct product concepts or key features that address the problem in new or improved ways. These should be based on the research insights – for example, solving the pain points identified in existing alternatives or leveraging an unmet user need. Each idea should be **original or a significant improvement** over what's currently available.
2. **User Value of Each Idea:** For each proposed concept/feature, explain **what it is and how it works** at a high level. Then describe **why it would be valuable to the user** – how does it improve the user’s experience or outcomes? Tie this to the personas and pain points from the research phase (e.g., Idea 1 solves a specific frustration that competitors haven’t addressed).
3. **Feasibility for Solo Dev:** Discuss the feasibility of each idea for a single developer. Highlight any that are **high-impact but low-effort**, meaning they deliver notable value with relatively modest development work. Consider whether you can leverage existing libraries or services to implement the idea quickly. If an idea is more complex, note what makes it challenging and any strategies to simplify it.
4. **Prioritization Rationale:** Provide a brief comparison of these ideas. Which idea (or combination of features) seems most promising for an initial product version, considering **impact vs. effort**? Identify the idea that offers the **best value for the development effort** and explain why it’s ideal for a solo developer to pursue first.

*Present the brainstorm results in a clear list (e.g., “**Idea 1:** ...”), so it’s easy to compare options. Emphasize creativity but keep solutions realistic for one person to build. The goal is to find an idea that will make a splash with users without over-scoping the initial development.*

## Plan

**Prompt (Plan Phase):** *Now that we have a chosen idea/feature set, create a detailed development plan. We need a roadmap tailored to a one-person team.*

1. **Milestones Roadmap:** Outline the key **development milestones** for the project. Define stages such as **MVP (Minimum Viable Product)**, **Beta**, and **v1.0** (full release), along with any intermediate checkpoints if needed. For each milestone, specify its **goal and scope** – what core features or functionality will be delivered at that stage. (For example, MVP might include just the one most crucial feature to solve the core problem, Beta might add additional nice-to-have features and polish, etc.)
2. **Epics & Tasks Breakdown:** For each milestone, break down the work into **epics** (major components or feature sets) and smaller tasks or user stories under those epics. List the epics that need to be completed (e.g. “User Authentication Module,” “Core Data Processing Engine,” “UI for Feature X”) and then list key tasks for each epic (e.g. “Implement login API,” “Design login page UI,” “Set up database schema for user accounts”). The task breakdown should be detailed enough to guide implementation but grouped logically to avoid overwhelm.
3. **Timeline & Resource Estimate:** Provide a rough time estimate for each milestone and epic, **appropriate for a single developer**. For example, estimate how many weeks each milestone might take given a reasonable pace. Consider the solo developer’s capacity (no parallel teams), and note if certain tasks can be done concurrently or must be sequential. This helps in setting expectations and scheduling.
4. **Risk Analysis:** Identify potential **risks or challenges** in the project and associate them with the relevant milestone or epic. These could include technical uncertainties (e.g., unfamiliar technology, integration difficulties), scope risks (feature creep), or time risks. For each risk, suggest a **mitigation plan**. (For example: “Risk: Integration with payment API could be tricky – Mitigation: allocate extra time for research, have a fallback manual payment method if needed.”)
5. **Prioritization & Scope Control:** Describe how to prioritize tasks and manage scope as a solo developer. Emphasize building the most valuable features first (as identified in the Innovate phase) and deferring nice-to-have features. Include any plan for handling feedback or changing requirements (for instance, planning a Beta to gather user feedback and then adjust before v1.0).

*The plan should read like a mini project blueprint that one developer can follow. Ensure it’s realistic (given one person’s workload) and includes contingency thoughts. By the end of this prompt’s output, we should have a clear to-do list and timeline from now until launch (v1.0).*

## Execute

**Prompt (Execute Phase):** *It’s time to design and implement the solution. Provide guidance on system architecture, detailed design, and execution best practices.*

1. **High-Level Architecture:** Outline the overall architecture of the product. Identify the main components or layers of the system (for example: client application/front-end, server or backend API, database, third-party services, etc.) and explain the responsibilities of each. Describe how these components will interact. For clarity, you may include a simple diagram or outline (e.g., using a text-based diagram or list of components and arrows describing data flow). Ensure the architecture is **kept as simple as possible** while meeting requirements – suitable for a solo developer to build and manage.
2. **Detailed Component Design:** For each major component or epic from the plan, provide a more detailed design. This should include key modules/classes and their roles, important functions or methods, and data models (such as database schema or data structures). Where appropriate, write pseudocode, code scaffolds, or examples for critical sections of the code. (Use Markdown code blocks for clarity if presenting pseudocode or sample functions.) Emphasize **modular design principles** – components should be loosely coupled and highly cohesive, making them easier to develop and test in isolation and reuse in the future.
3. **Technology-Specific Considerations:** Highlight any important design decisions related to the chosen tech stack. For example, if using a particular framework, outline how project structure or patterns (MVC, MVVM, etc.) will be applied. If relevant, describe how to manage state, handle errors, or ensure security within this design. Ensure that these decisions align with **best practices** and maintainability (since one person will maintain this code, clarity is crucial).
4. **Testing Strategy:** Describe a comprehensive testing strategy for the project. This should cover:

   * **Unit Testing:** how to test individual functions or components (mention any frameworks or tools in the chosen stack that make unit testing easier).
   * **Integration Testing:** how to test that different modules work together correctly (for example, testing the API with the database, or the front-end with the back-end API endpoints).
   * **Regression Testing:** how to continually run tests to catch bugs when changes are made. (Consider setting up a suite of tests that can be run automatically whenever new code is added, to ensure new changes don’t break existing functionality.)
     Also, suggest practices like Test-Driven Development (if suitable) or at least writing tests alongside code. Emphasize that as a solo dev, having good tests is a safety net to enable quick changes with confidence.
5. **CI/CD Pipeline (Solo-Friendly):** Propose a simple Continuous Integration/Continuous Deployment pipeline appropriate for a one-person team. For example, recommend using a service (like GitHub Actions, GitLab CI, or similar) to automatically run the test suite on each commit. Describe how to automate builds and deployments – perhaps deploying to a platform (e.g., cloud service or container platform) whenever code is pushed to a main branch and tests pass. Keep the CI/CD setup minimal and easy to maintain (the goal is to save time, not create overhead). Include any safeguards (like running tests in CI, or requiring a manual approval for deployment if that makes sense for solo work).

*Focus on providing enough detail that the solo developer (and the AI assistant) can start coding from this plan. The output should be part design document and part execution guide. It must balance ambition with pragmatism – using modern architecture and practices, but avoiding over-engineering since one person must implement and maintain it.*

## Review

**Prompt (Review Phase):** *Finally, generate a complete documentation and review package for the project. This will serve as both user and developer documentation, and a retrospective for learning.*

1. **Requirements & Product Summary:** Start with a high-level **requirements document**. Summarize the original problem and the goals of the product. List the core features that were implemented (from MVP to v1.0) and the user personas or use-cases they address. This is effectively the “product spec” that someone can read to understand what the software is supposed to do and why.
2. **Technical Documentation:** Provide comprehensive technical details of the final product:

   * Outline the final architecture, referencing the major components and how they interact (this can recap the architecture from the Execute phase, updated to reflect the actual implementation if it changed).
   * Document important **architecture decisions** made during development (e.g., “Chose X framework for Y reason”, “Decided to use a NoSQL DB to simplify deployment”, etc.), including the rationale and any alternatives considered.
   * Include details of how to navigate the codebase (e.g., key directories, how classes or modules are organized) so that either the solo developer in the future or any new collaborator can quickly orient themselves.
3. **Usage and Setup Instructions:** Write clear **usage documentation** for the project. This should include:

   * Installation or deployment steps (for example, how to install dependencies, set up environment variables or configuration, run database migrations if any, and start the application).
   * Instructions for using the software from an end-user perspective (or API usage examples if it’s a library or service).
   * Any troubleshooting tips for common issues a user or developer might encounter when running the software.
4. **Maintenance Plan & Monitoring:** Describe a plan for maintaining the project over time:

   * How will the solo developer manage updates to dependencies and security patches?
   * What is the strategy for monitoring the application in production (e.g., error logging, performance monitoring, uptime checks)? List a basic **monitoring checklist** or tools (for instance, “Set up alerts for server errors, monitor CPU/memory if applicable, regularly check logs for unusual activities”).
   * Include any scheduling for regular maintenance tasks (backups, updates, etc.), and strategies for handling user support or bug reports as a one-person team.
5. **Retrospective & Lessons Learned:** Conclude with a **retrospective analysis** of the project. Reflect on what went well and what didn’t throughout the development process:

   * Discuss challenges encountered and how they were overcome.
   * Highlight which practices or decisions were particularly effective (for example, “Using framework X saved a lot of time” or “Setting up automated tests caught bugs early”).
   * Note any areas for improvement in future projects (e.g., “Next time, allocate more time for refining UX,” or “Consider using library Y to simplify Z aspect”).
   * If there were things that had to be cut or deferred, mention them and potential future enhancements.
     The goal is to capture **lessons learned** that can inform the next iteration of the product or the next project the developer undertakes.

*Ensure the documentation is well-organized and written in clear, concise language. It should serve as a **single source of truth** for understanding and maintaining the product. The retrospective should provide honest insights for continuous improvement. By the end of this phase’s output, we should have a complete package that not only helps in using and supporting the current product but also guides future solo development efforts with the wisdom gained.*

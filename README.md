# Digital Archaeological Site Management System

A comprehensive blockchain-based system for managing archaeological sites, excavations, artifacts, and public access using Clarity smart contracts.

## Overview

This system consists of five interconnected smart contracts that manage different aspects of archaeological site operations:

1. **Excavation Permit Contract** - Authorizes and tracks archaeological dig activities
2. **Artifact Cataloging Contract** - Records discovered items and their provenance
3. **Site Preservation Contract** - Protects historical locations from damage
4. **Research Collaboration Contract** - Enables academic partnerships and data sharing
5. **Public Access Contract** - Manages tourist visits and educational programs

## Features

### Excavation Permits
- Issue permits to qualified archaeologists
- Track permit status and expiration dates
- Monitor excavation progress and compliance
- Manage permit renewals and revocations

### Artifact Cataloging
- Register discovered artifacts with detailed metadata
- Track provenance and chain of custody
- Assign unique identifiers to each artifact
- Record conservation status and location

### Site Preservation
- Monitor site condition and threats
- Track preservation activities and funding
- Manage access restrictions and protective measures
- Record environmental impact assessments

### Research Collaboration
- Facilitate partnerships between institutions
- Share research data and findings securely
- Manage publication rights and attribution
- Track collaborative project progress

### Public Access
- Schedule and manage tourist visits
- Provide educational program registration
- Monitor visitor capacity and impact
- Generate revenue tracking for site maintenance

## Contract Architecture

Each contract operates independently while maintaining data integrity through careful state management. The system uses principal-based access control and time-based validations.

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Basic understanding of Clarity smart contracts

### Installation

\`\`\`bash
git clone <repository-url>
cd archaeological-site-management
npm install
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy
\`\`\`

## Usage Examples

### Issuing an Excavation Permit

\`\`\`clarity
(contract-call? .excavation-permits issue-permit
'SP1ARCHAEOLOGIST
u1000
"Ancient Roman Villa Site")
\`\`\`

### Cataloging an Artifact

\`\`\`clarity
(contract-call? .artifact-catalog register-artifact
"Roman Coin - Denarius"
"Silver coin from 1st century CE"
u1
'SP1ARCHAEOLOGIST)
\`\`\`

### Scheduling Public Access

\`\`\`clarity
(contract-call? .public-access schedule-visit
'SP1VISITOR
u20240315
u10)
\`\`\`

## Data Structures

### Permit Structure
- permit-id: uint
- archaeologist: principal
- site-id: uint
- issue-date: uint
- expiry-date: uint
- status: string-ascii
- site-description: string-utf8

### Artifact Structure
- artifact-id: uint
- name: string-utf8
- description: string-utf8
- site-id: uint
- discoverer: principal
- discovery-date: uint
- conservation-status: string-ascii

### Site Structure
- site-id: uint
- name: string-utf8
- location: string-utf8
- threat-level: uint
- last-assessment: uint
- protection-status: string-ascii

## Security Considerations

- All contracts implement proper access controls
- Time-based validations prevent expired operations
- Principal verification ensures authorized actions
- State consistency maintained across operations

## Contributing

Please read the PR-DETAILS.md file for contribution guidelines and development standards.

## License

This project is licensed under the MIT License.

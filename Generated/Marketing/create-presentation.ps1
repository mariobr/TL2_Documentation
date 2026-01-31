# Create PowerPoint presentation from marketing overview
param(
    [string]$OutputPath = "TrustedLicensing365_Presentation.pptx"
)

# Create PowerPoint application object
$powerpoint = New-Object -ComObject PowerPoint.Application
$powerpoint.Visible = 1  # msoTrue

# Create new presentation
$presentation = $powerpoint.Presentations.Add()

# Set slide size to widescreen (16:9)
$presentation.PageSetup.SlideWidth = 960
$presentation.PageSetup.SlideHeight = 540

# Define color scheme
$darkBlue = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::FromArgb(0, 51, 102))
$lightBlue = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::FromArgb(0, 120, 215))
$white = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::White)
$gray = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::FromArgb(100, 100, 100))

function Add-TitleSlide {
    param($presentation, $title, $subtitle)
    
    $slide = $presentation.Slides.Add($presentation.Slides.Count + 1, 1) # ppLayoutTitle
    $slide.Shapes.Title.TextFrame.TextRange.Text = $title
    $slide.Shapes.Title.TextFrame.TextRange.Font.Size = 54
    $slide.Shapes.Title.TextFrame.TextRange.Font.Bold = $true
    $slide.Shapes.Title.TextFrame.TextRange.Font.Color.RGB = $darkBlue
    
    if ($slide.Shapes.Count -ge 2) {
        $slide.Shapes[2].TextFrame.TextRange.Text = $subtitle
        $slide.Shapes[2].TextFrame.TextRange.Font.Size = 28
        $slide.Shapes[2].TextFrame.TextRange.Font.Color.RGB = $gray
    }
}

function Add-ContentSlide {
    param($presentation, $title, $content)
    
    $slide = $presentation.Slides.Add($presentation.Slides.Count + 1, 2) # ppLayoutText
    $slide.Shapes.Title.TextFrame.TextRange.Text = $title
    $slide.Shapes.Title.TextFrame.TextRange.Font.Size = 40
    $slide.Shapes.Title.TextFrame.TextRange.Font.Bold = $true
    $slide.Shapes.Title.TextFrame.TextRange.Font.Color.RGB = $darkBlue
    
    if ($slide.Shapes.Count -ge 2) {
        $slide.Shapes[2].TextFrame.TextRange.Text = $content
        $slide.Shapes[2].TextFrame.TextRange.Font.Size = 18
    }
}

function Add-BulletSlide {
    param($presentation, $title, [string[]]$bullets)
    
    $slide = $presentation.Slides.Add($presentation.Slides.Count + 1, 2) # ppLayoutText
    $slide.Shapes.Title.TextFrame.TextRange.Text = $title
    $slide.Shapes.Title.TextFrame.TextRange.Font.Size = 40
    $slide.Shapes.Title.TextFrame.TextRange.Font.Bold = $true
    $slide.Shapes.Title.TextFrame.TextRange.Font.Color.RGB = $darkBlue
    
    if ($slide.Shapes.Count -ge 2) {
        $textFrame = $slide.Shapes[2].TextFrame
        $textRange = $textFrame.TextRange
        $textRange.Text = ($bullets -join "`n")
        $textRange.Font.Size = 20
        
        # Apply bullet formatting
        foreach ($para in $textRange.Paragraphs()) {
            $para.ParagraphFormat.Bullet.Type = 1 # ppBulletNumbered
        }
    }
}

Write-Host "Creating presentation..." -ForegroundColor Cyan

# Slide 1: Title
Add-TitleSlide -presentation $presentation -title "Trusted Licensing 365" -subtitle "Transform Your Software Licensing in Days"

# Slide 2: The Challenge
Add-BulletSlide -presentation $presentation -title "The Challenge Software Vendors Face" -bullets @(
    "Rigid licensing can't adapt to customer demands",
    "Software-only licensing vulnerable to tampering and piracy",
    "Building licensing infrastructure diverts resources from core product",
    "Custom licensing solutions take months to develop",
    "Managing licenses across distributed environments is complex"
)

# Slide 3: The Solution
Add-ContentSlide -presentation $presentation -title "The Trusted Licensing 365 Solution" -content @"
A complete, white-label licensing platform that integrates with your software in hours, backed by military-grade hardware security.

✓ Rapid Integration - Hours, Not Months
✓ Military-Grade Security - No Effort Required
✓ 11 Revenue Models - One Platform
✓ Multi-Tenant Architecture - Scale Effortlessly
"@

# Slide 4: Rapid Integration
Add-BulletSlide -presentation $presentation -title "🚀 Rapid Integration - Hours, Not Months" -bullets @(
    "Time to First License: 4-8 Hours",
    "Hour 1-2: Onboard to platform, configure vendor instance",
    "Hour 3-4: Define first product and license model",
    "Hour 5-6: Integrate client library into application",
    "Hour 7-8: Generate and activate first license",
    "No specialized security expertise required"
)

# Slide 5: Security
Add-BulletSlide -presentation $presentation -title "🔒 Military-Grade Security" -bullets @(
    "TPM 2.0 Integration - Licenses bound to customer hardware",
    "Tamper Detection - Built-in VM rollback detection",
    "Cryptographic Trust - Multi-layer encryption",
    "Zero Security Code - Platform handles all security",
    "Hardware-backed protection with no development effort"
)

# Slide 6: 11 Revenue Models
Add-BulletSlide -presentation $presentation -title "💰 11 Revenue Models - One Platform" -bullets @(
    "Perpetual licenses for enterprise customers",
    "Subscription renewals with automatic billing",
    "Pay-per-use (counter-based)",
    "Cloud credits (token-based)",
    "Time-limited trials",
    "Named user licensing",
    "Floating licenses with concurrent user limits",
    "Exportable licenses for customer redistribution"
)

# Slide 7: Integration Speed
$slide = $presentation.Slides.Add($presentation.Slides.Count + 1, 2)
$slide.Shapes.Title.TextFrame.TextRange.Text = "Integration Complexity: Minimal"
$slide.Shapes.Title.TextFrame.TextRange.Font.Size = 36
$slide.Shapes.Title.TextFrame.TextRange.Font.Bold = $true
$slide.Shapes.Title.TextFrame.TextRange.Font.Color.RGB = $darkBlue

$tableContent = @"
Integration Type          Time Required    Effort Level
REST API Integration      2-4 hours        Low
Client Library            4-8 hours        Low
License Manager Service   1-2 hours        Minimal
Identity Integration      2-4 hours        Low
"@

$slide.Shapes[2].TextFrame.TextRange.Text = $tableContent
$slide.Shapes[2].TextFrame.TextRange.Font.Size = 16
$slide.Shapes[2].TextFrame.TextRange.Font.Name = "Consolas"

# Slide 8: Deployment Speed
Add-BulletSlide -presentation $presentation -title "Deployment Speed: Same Day" -bullets @(
    "Cloud (Shared Instance): Immediate setup",
    "Cloud (Dedicated Instance): 2-4 hours",
    "On-Premise (Docker): 4-8 hours",
    "On-Premise (Kubernetes): 8-16 hours",
    "All deployment options containerized and scalable"
)

# Slide 9: Go-To-Market Timeline
Add-BulletSlide -presentation $presentation -title "Business Readiness: 1-5 Days" -bullets @(
    "Day 1: Platform onboarding and branding",
    "Day 2: Product catalog setup",
    "Day 3: Development integration",
    "Day 4: Customer pilot",
    "Day 5: Production launch",
    "Week 2+: Scale to additional products and markets"
)

# Slide 10: Business Benefits
Add-BulletSlide -presentation $presentation -title "Business Benefits" -bullets @(
    "Revenue Optimization: Convert perpetual to subscription",
    "Cost Reduction: Eliminate development overhead",
    "Risk Mitigation: Hardware-backed revenue protection",
    "Operational Efficiency: Automated license management",
    "Upsell Opportunities: Feature-gated tiers",
    "Compliance & Governance: Complete audit trail"
)

# Slide 11: Platform Agnostic
Add-BulletSlide -presentation $presentation -title "🌐 Works Everywhere Your Software Does" -bullets @(
    "Operating Systems: Windows, Linux",
    "Deployment: Physical servers, VMs, Docker, Kubernetes",
    "Network Modes: Online, offline, air-gapped",
    "Architectures: x86, ARM, cloud-native",
    "Seamless multi-platform support"
)

# Slide 12: White-Label Freedom
Add-BulletSlide -presentation $presentation -title "🎨 White-Label Freedom" -bullets @(
    "Customize all customer-facing portals",
    "Define your own product tiers (Free, Pro, Enterprise)",
    "Set your own pricing models",
    "Control feature access and limitations",
    "No 'Powered by' requirements",
    "Your brand, your rules"
)

# Slide 13: Technology Highlights
Add-BulletSlide -presentation $presentation -title "Technology Highlights" -bullets @(
    "TPM 2.0 hardware security integration",
    "OAuth 2.0 / OpenID Connect (SSO ready)",
    "RESTful APIs for all operations",
    "Cloud-native microservices architecture",
    "Docker & Kubernetes support",
    "Multi-region deployment"
)

# Slide 14: Customer Success
Add-BulletSlide -presentation $presentation -title "Customer Success Scenarios" -bullets @(
    "SaaS Vendors: Deployed in 2 days, 40% subscription conversion increase",
    "Enterprise Software: Smooth perpetual-to-subscription migration",
    "IoT/Edge Computing: 1 week integration, 50,000+ devices supported",
    "ISV Partners: Partner channel enabled in 3 days",
    "Proven across industries and use cases"
)

# Slide 15: Why Choose TL365
Add-BulletSlide -presentation $presentation -title "Why Vendors Choose Trusted Licensing 365" -bullets @(
    "✅ Speed: Live in days, not months",
    "✅ Security: Hardware-backed, no expertise required",
    "✅ Flexibility: 11 license models, unlimited combinations",
    "✅ Scale: From startup to enterprise",
    "✅ Control: White-label, your brand",
    "✅ Support: Expert guidance throughout"
)

# Slide 16: Next Steps
Add-BulletSlide -presentation $presentation -title "Next Steps" -bullets @(
    "Schedule a Demo: See the platform with your use case",
    "Start a Pilot: Free sandbox for 30 days",
    "Technical Deep-Dive: Architecture review with engineering",
    "",
    "Ready to transform your licensing?",
    "Contact us today to get started"
)

# Slide 17: Closing
Add-TitleSlide -presentation $presentation -title "Trusted Licensing 365" -subtitle "Enterprise Licensing, Simplified"

# Save presentation
$fullPath = Join-Path (Get-Location) $OutputPath
$presentation.SaveAs($fullPath)

Write-Host "✓ Presentation created: $fullPath" -ForegroundColor Green

# Close PowerPoint
$presentation.Close()
$powerpoint.Quit()

# Release COM objects
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($presentation) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($powerpoint) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Write-Host "Done! Presentation ready for use." -ForegroundColor Cyan

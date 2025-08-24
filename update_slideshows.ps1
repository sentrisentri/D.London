# Get all product HTML files (excluding main pages)
$productFiles = Get-ChildItem -Path "d:\D-London" -Name "*.html" | Where-Object { 
    $_ -notmatch "^(index|collections|lookbook|about|contact|bridal|cocktail-dresses|occasion-dresses|workwear)\.html$"
}

$updatedCount = 0
$errorCount = 0

foreach ($htmlFile in $productFiles) {
    # Skip already updated files
    if ($htmlFile -eq "bandeau-bridal-dress.html" -or $htmlFile -eq "midi-dress-lilac-floralprint.html") {
        Write-Host "Skipping already updated: $htmlFile"
        continue
    }
    
    # Get product name from HTML filename (remove .html extension)
    $productName = [System.IO.Path]::GetFileNameWithoutExtension($htmlFile)
    
    # Check if corresponding product folder exists
    $productFolder = "d:\D-London\images\Product\$productName"
    if (-not (Test-Path $productFolder)) {
        Write-Host "Warning: No product folder found for $productName"
        $errorCount++
        continue
    }
    
    # Get all images in the product folder
    $images = Get-ChildItem -Path $productFolder -Filter "*.jpg" | Sort-Object Name
    if ($images.Count -eq 0) {
        Write-Host "Warning: No images found in folder for $productName"
        $errorCount++
        continue
    }
    
    Write-Host "Processing $htmlFile with $($images.Count) images..."
    
    # Read the HTML file
    $htmlContent = Get-Content -Path "d:\D-London\$htmlFile" -Raw
    
    # Generate the slides HTML
    $slidesHtml = ""
    $indicatorsHtml = ""
    
    for ($i = 0; $i -lt $images.Count; $i++) {
        $imageNum = $i + 1
        $activeClass = if ($i -eq 0) { " active" } else { "" }
        $imagePath = "images/Product/$productName/$($images[$i].Name)"
        
        $slidesHtml += @"
                <div class="slide$activeClass">
                    <img src="$imagePath" alt="$($htmlFile -replace '\.html$', '') - View $imageNum">
                </div>
"@
        
        $indicatorActiveClass = if ($i -eq 0) { " active" } else { "" }
        $indicatorsHtml += @"
                    <span class="indicator$indicatorActiveClass" onclick="currentSlide($imageNum)"></span>
"@
    }
    
    # Create the complete slideshow HTML
    $newSlideshowHtml = @"
    <!-- Product Gallery -->
    <section class="product-gallery">
        <div class="container">
            <div class="slideshow-container">
$slidesHtml
                
                <!-- Navigation arrows -->
                <button class="prev-btn" onclick="changeSlide(-1)">&#10094;</button>
                <button class="next-btn" onclick="changeSlide(1)">&#10095;</button>
                
                <!-- Slide indicators -->
                <div class="slide-indicators">
$indicatorsHtml
                </div>
            </div>
        </div>
    </section>
"@
    
    # Use regex to replace the product gallery section
    $pattern = '(?s)    <!-- Product Gallery -->.*?    </section>'
    if ($htmlContent -match $pattern) {
        $updatedContent = $htmlContent -replace $pattern, $newSlideshowHtml
        Set-Content -Path "d:\D-London\$htmlFile" -Value $updatedContent -Encoding UTF8
        Write-Host "Successfully updated: $htmlFile"
        $updatedCount++
    } else {
        Write-Host "Error: Could not find slideshow section in $htmlFile"
        $errorCount++
    }
}

Write-Host "`nUpdate Summary:"
Write-Host "Successfully updated: $updatedCount files"
Write-Host "Errors encountered: $errorCount files"

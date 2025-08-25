#!/bin/bash

# File Organization Script for Document/Research Template
# Organizes audio files, HTML files, and documents

echo "🔧 Starting file organization..."

# Create directory structure
mkdir -p {audio,reports,documents,research,assets,templates}

# Create the new index.html by injecting content
echo "🌐 Creating new index.html from template..."
if [ -f "weitj.html" ] && [ -f "enhanced-index.html" ]; then
    # Extract body content from the source file
    echo " extracting content from weitj.html..."
    sed -n '/<body.*>/,/\/body>/p' weitj.html > body_content.html

    # Inject the body content into the template
    echo " injecting content into the template..."
    sed -e '/<!-- main-content-placeholder -->/r body_content.html' -e '/<!-- main-content-placeholder -->/d' enhanced-index.html > index.html

    # Clean up the temporary file
    rm body_content.html
else
    echo "⚠️  Warning: weitj.html or enhanced-index.html not found. Using enhanced-index.html as a fallback."
    cp enhanced-index.html index.html
fi

# Move the email template to a known location
if [ -f "email-template.html" ]; then
    mv email-template.html templates/
fi

# Process audio files - rename to standardized format
echo "📁 Processing audio files..."
for file in *.mp3 *.wav *.m4a *.aac *.flac; do
    if [ -f "$file" ]; then
        # Get base name without extension
        basename="${file%.*}"
        extension="${file##*.}"
        
        # Rename to audio_[original-name].[ext]
        new_name="audio_${basename}.${extension}"
        mv "$file" "audio/$new_name"
        echo "  ✓ Moved $file → audio/$new_name"
    fi
done

# Process document files
echo "📋 Processing documents..."
for ext in pdf docx doc txt md; do
    for file in *.$ext; do
        if [ -f "$file" ]; then
            mv "$file" "documents/"
            echo "  ✓ Moved $file → documents/"
        fi
    done
done

# Process research files (images, data, etc.)
echo "🔬 Processing research assets..."
for ext in png jpg jpeg gif svg csv json xml; do
    for file in *.$ext; do
        if [ -f "$file" ]; then
            mv "$file" "research/"
            echo "  ✓ Moved $file → research/"
        fi
    done
done

# Process HTML files (after index.html is created)
echo "📄 Processing HTML files..."
for file in *.html; do
    if [ -f "$file" ] && [ "$file" != "index.html" ]; then
        # Get file size
        size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
        
        if [ "$size" -lt 10240 ]; then  # Less than 10KB = shorter/email version
            mv "$file" "reports/email_${file}"
            echo "  ✓ Moved $file → reports/email_${file} (smaller file)"
        else  # Larger file = website version
            if [ "$file" != "index.html" ]; then
                mv "$file" "reports/website_${file}"
                echo "  ✓ Moved $file → reports/website_${file} (larger file)"
            fi
        fi
    fi
done

# Generate email template for each HTML report
echo "📧 Creating email templates..."
for file in reports/email_*.html reports/website_*.html; do
    if [ -f "$file" ] && [ -f "templates/email-template.html" ]; then
        # Extract base name without path and extension
        basename_file=$(basename "$file" .html)
        
        # Create email template for this report
        sed "s|#github-link.*href=\"#\"|href=\"https://$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')\"|g" templates/email-template.html > "reports/email_${basename_file}_summary.html"
        
        echo "  ✓ Created email summary for $file"
    fi
done

# Update main template with file discovery
echo "🔄 Updating file listings in main template..."

echo "✅ File organization complete!"
echo ""
echo "📁 Directory structure:"
echo "  ├── audio/          - Audio files (renamed with audio_ prefix)"
echo "  ├── reports/        - HTML files (email_ for small, website_ for large)"
echo "  ├── documents/      - PDF, DOC, TXT, MD files"
echo "  ├── research/       - Images, data files, research assets"
echo "  └── index.html      - Main template page"
echo ""
echo "💡 Usage: Place files in root directory and run './organize-files.sh'"
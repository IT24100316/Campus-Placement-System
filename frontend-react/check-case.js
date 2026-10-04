import fs from 'fs';
import path from 'path';

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(function(file) {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) { 
            results = results.concat(walk(file));
        } else { 
            if (file.endsWith('.ts') || file.endsWith('.tsx')) {
                results.push(file);
            }
        }
    });
    return results;
}

const files = walk('./src');
let hasError = false;

for (const file of files) {
    const content = fs.readFileSync(file, 'utf8');
    const importRegex = /import\s+.*?\s+from\s+['"]([^'"]+)['"]/g;
    let match;
    while ((match = importRegex.exec(content)) !== null) {
        const importPath = match[1];
        if (importPath.startsWith('.')) {
            const absolutePath = path.resolve(path.dirname(file), importPath);
            // Check if file exists (TypeScript adds .ts/.tsx extensions automatically)
            const extensions = ['.ts', '.tsx', '.js', '.jsx', '.json'];
            let found = false;
            let exactMatch = false;
            for (const ext of extensions) {
                const fullPath = absolutePath + ext;
                if (fs.existsSync(fullPath)) {
                    found = true;
                    // Check exact casing on Windows by reading directory
                    const dir = path.dirname(fullPath);
                    const basename = path.basename(fullPath);
                    if (fs.existsSync(dir)) {
                        const realFiles = fs.readdirSync(dir);
                        if (!realFiles.includes(basename)) {
                            console.error(`Case mismatch in ${file}: imported '${importPath}' but real file is different casing.`);
                            hasError = true;
                        } else {
                            exactMatch = true;
                        }
                    }
                    break;
                }
            }
            if (!found) {
                // maybe it's a directory import with index.ts
                const indexPath = path.join(absolutePath, 'index.ts');
                if (fs.existsSync(indexPath)) {
                    const realFiles = fs.readdirSync(absolutePath);
                    if (!realFiles.includes('index.ts')) {
                        console.error(`Case mismatch in directory ${file}: ${importPath}`);
                        hasError = true;
                    }
                }
            }
        }
    }
}
if (!hasError) console.log("No case mismatches found!");

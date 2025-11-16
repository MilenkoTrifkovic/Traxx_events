module.exports = {
    // Google style guide preferences
    printWidth: 80,
    tabWidth: 2,
    useTabs: false,
    semi: true,
    singleQuote: false, // Google style uses double quotes
    quoteProps: "as-needed",
    trailingComma: "es5",
    bracketSpacing: false, // Google style: {foo} instead of { foo }
    bracketSameLine: false,
    arrowParens: "always",
    endOfLine: "lf",

    // Override for specific file types if needed
    overrides: [
        {
            files: "*.json",
            options: {
                printWidth: 200,
            },
        },
    ],
};
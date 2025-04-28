module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2020,
  },
  extends: [
    'eslint:recommended',
  ],
  rules: {
    quotes: ['error', 'single'],
    'max-len': ['error', { 'code': 120 }],
    'linebreak-style': 0,
    'indent': ['error', 2],
    'no-unused-vars': 'warn',
    'object-curly-spacing': ['off'],
    'comma-dangle': ['off'],
    'no-trailing-spaces': ['off'],
    'require-jsdoc': 'off',
    'quote-props': 'off',
    'eol-last': 'off'
  },
  overrides: [
    {
      files: ['**/*.spec.*'],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};

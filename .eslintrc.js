const fs = require('fs');

const prettierConfig = fs.readFileSync('./.prettierrc', 'utf8');
const prettierOptions = JSON.parse(prettierConfig);
const isProduction = process.env.NODE_ENV === 'production';

module.exports = {
  extends: ['airbnb-base', 'prettier'],
  env: {
    node: true,
    jest: true,
    es2020: true,
  },
  plugins: ['json', 'prettier'],
  parser: '@babel/eslint-parser',
  settings: {
    'import/resolver': {
      node: {
        extensions: ['.ts', '.js'],
        moduleDirectory: ['node_modules', 'deploy', 'scripts', 'tasks', 'test'],
      },
    },
  },
  parserOptions: {
    project: './tsconfig.json',
    sourceType: 'module',
    typescript: true,
    ecmaVersion: 2020,
    experimentalDecorators: true,
    requireConfigFile: false,
    ecmaFeatures: {
      classes: true,
      impliedStrict: true,
    },
  },
  reportUnusedDisableDirectives: isProduction,
  rules: {
    'no-await-in-loop': 'off',
    'import/no-import-module-exports': 'off',
    'import/no-extraneous-dependencies': ['off'],
    'no-debugger': isProduction ? 'error' : 'off',
    'no-console': isProduction ? 'error' : 'off',
    'no-plusplus': 'off',
    'no-console': 'off',
    'no-underscore-dangle': 'error',
    'no-redeclare': [
      'error',
      {
        builtinGlobals: true,
      },
    ],
    'prettier/prettier': ['error', prettierOptions],
    'import/prefer-default-export': 'off',
    'import/extensions': [
      'error',
      'ignorePackages',
      {
        js: 'never',
        ts: 'never',
        json: 'always',
      },
    ],
    'class-methods-use-this': 'off',
    'prefer-promise-reject-errors': 'off',
    'max-classes-per-file': 'off',
    'no-use-before-define': ['off'],
    'no-shadow': 'off',
  },
  overrides: [
    {
      files: ['**/*.ts', '**/*.tsx'],
      parser: '@typescript-eslint/parser',
      extends: [
        'plugin:@typescript-eslint/eslint-recommended',
        'plugin:@typescript-eslint/recommended',
        'plugin:@typescript-eslint/recommended-requiring-type-checking',
      ],
      plugins: ['@typescript-eslint', 'prettier'],
      parserOptions: {
        project: ['./tsconfig.json'],
        warnOnUnsupportedTypeScriptVersion: true,
      },
      rules: {
        '@typescript-eslint/no-floating-promises': 'off',
        '@typescript-eslint/no-explicit-any': 'error',
        '@typescript-eslint/explicit-module-boundary-types': 'error',
        '@typescript-eslint/no-use-before-define': [
          'error',
          {
            functions: false,
            classes: false,
          },
        ],
        '@typescript-eslint/no-shadow': [
          'error',
          {
            builtinGlobals: true,
            allow: [
              'location',
              'event',
              'history',
              'name',
              'status',
              'screen',
              'expect',
            ],
          },
        ],
      },
    },
  ],
};

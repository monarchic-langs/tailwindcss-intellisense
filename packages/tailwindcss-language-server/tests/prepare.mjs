import { exec } from 'node:child_process'
import * as path from 'node:path'
import { fileURLToPath } from 'node:url'
import { promisify } from 'node:util'
import { glob } from 'tinyglobby'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const root = path.resolve(__dirname, '..')

if (process.env.TAILWINDCSS_INTELLISENSE_SKIP_FIXTURE_INSTALL === '1') {
  console.log('Skipping fixture dependency installation')
  process.exit(0)
}

const fixtures = await glob({
  cwd: root,
  patterns: ['tests/fixtures/*/package.json', 'tests/fixtures/v4/*/package.json'],
  absolute: true,
})

const execAsync = promisify(exec)

await Promise.all(
  fixtures.map(async (fixture) => {
    console.log(`Installing dependencies for ${path.relative(root, fixture)}`)

    await execAsync('npm install', { cwd: path.dirname(fixture) })
  }),
)

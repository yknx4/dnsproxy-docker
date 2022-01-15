import { Octokit } from "@octokit/rest"
import { queryTags, queryRepo } from 'docker-hub-utils'
import { writeFileSync } from 'fs'

const OUTPUT_FOLDER = process.env.GITHUB_WORKSPACE ?? '/tmp'

async function main() {
  const octokit = new Octokit()
  const releases = await octokit.rest.repos.listReleases({
    owner: "AdguardTeam",
    repo: "dnsproxy"
  })

  const repo = await queryRepo({ user: 'yknx94', name: "dnsproxy" })
  const dockerImages = await queryTags(repo!)
  const finalTags = []

  for (const release of releases.data) {
    const hasDockerImage = dockerImages!.some(t => t.name == release.tag_name) ?? true
    if (hasDockerImage) {
      console.log(`Skipping DnsProxy ${release.name} because docker image already exists.`)
    } else {
      console.log(`Building DnsProxy ${release.name}.`)
      finalTags.push(release.tag_name)
    }
  }

  await writeFileSync(`${OUTPUT_FOLDER}/matrix.json`, JSON.stringify({ include: finalTags.map(tag => ({ tag })) }))
}

main().catch(e => {
  console.error(e)
  process.exit(1)
})
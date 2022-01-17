import { Octokit } from "@octokit/rest"
import { queryTags, queryRepo } from 'docker-hub-utils'
import { writeFileSync } from 'fs'

const OUTPUT_FOLDER = process.env.GITHUB_WORKSPACE ?? '/tmp'

async function main(owner: string, repo: string, arch: string) {
  const octokit = new Octokit()
  const releases = await octokit.rest.repos.listReleases({
    owner,
    repo
  })

  const repoData = await queryRepo({ user: 'yknx94', name: "dnsproxy" })
  const dockerImages = await queryTags(repoData!)
  const finalTags = []

  for (const release of releases.data) {
    const hasDockerImage = dockerImages!.some(t => t.name == release.tag_name && t.images.some(i => i.architecture === arch)) ?? true
    if (hasDockerImage) {
      console.log(`Skipping DnsProxy ${release.name} because docker image already exists.`)
    } else {
      console.log(`Building DnsProxy ${release.name}.`)
      finalTags.push({
        tag: release.tag_name,
        arch,
        asset: release.assets.find(a => a.name.includes(arch))?.browser_download_url
      })
    }
  }

  await writeFileSync(`${OUTPUT_FOLDER}/matrix.json`, JSON.stringify({ include: finalTags }))
}

main(process.argv[2], process.argv[3], process.argv[4]).catch(e => {
  console.error(e)
  process.exit(1)
})
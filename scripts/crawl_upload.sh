readonly THIS_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd | xargs realpath)"
readonly ROOT_DIR="${THIS_DIR}/.."

readonly TEMP_DIR='/tmp/scratchers-crawl'

function main() {
    if [[ $# -ne 0 ]]; then
        echo "USAGE: $0"
        exit 1
    fi

    set -e
    trap exit SIGINT

    rm -rf "${TEMP_DIR}"
    mkdir "${TEMP_DIR}"
    cd "${TEMP_DIR}"

    local datestamp=$(date -u +%Y-%m-%dT%TZ)

    local code_url='git@github.com:eriq-augustine/scratchers.git'
    if [[ -v SCRATCHERS_PAT ]] ; then
        code_url="https://eriq-augustine:${SCRATCHERS_PAT}@github.com/eriq-augustine/scratchers.git"
    fi

    echo "Cloning Repos"
    git clone "${code_url}"
    git clone git@github.com:eriq-augustine/scratchers-data.git

    cd scratchers

    echo "Installing Dependencies"
    python3 -m venv venv
    source ./venv/bin/activate
    pip install -r requirements.txt -r requirements-dev.txt


    echo "Crawling"
    python3 -m scratchers.cli.crawl | gzip > data.json.gz

    echo "Computing Stats"
    python3 -m scratchers.cli.compute-game-stats data.json.gz --simulation --update

    cp data.json.gz "../scratchers-data/data/${datestamp}.json.gz"

    echo "Building Site"
    rm -r ../scratchers-data/docs
    python3 -m scratchers.cli.build-site ../scratchers-data/data --out-dir ../scratchers-data/docs

    echo "Deploying"
    cd ../scratchers-data
    git add .
    git -c user.email='s-crawl@eriqaugustine.com' -c user.name='Scratchers Crawl' commit -m "Updated data."
    git push

    return 0
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"

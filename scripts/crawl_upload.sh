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

    git clone git@github.com:eriq-augustine/scratchers.git
    git clone git@github.com:eriq-augustine/scratchers-data.git

    cd scratchers

    python3 -m venv venv
    source ./venv/bin/activate
    pip install -r requirements.txt -r requirements-dev.txt

    python3 -m scratchers.cli.crawl | gzip > data.json.gz

    python3 -m scratchers.cli.compute-game-stats data.json.gz --simulation --update

    cp data.json.gz "../scratchers-data/data/${datestamp}.json.gz"

    rm -r ../scratchers-data/docs
    python3 -m scratchers.cli.build-site ../scratchers-data/data --out-dir ../scratchers-data/docs

    cd ../scratchers-data
    git add .
    git commit -m "Updated data." --author "Scratchers Crawl <s-crawl@eriqaugustine.com>"
    git push

    return 0
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"

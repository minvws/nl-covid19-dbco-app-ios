version=$(git rev-parse --verify HEAD | cut -c 1-7)

filesource="/*\n * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.\n *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2\n *\n *  SPDX-License-Identifier: EUPL-1.2\n */\n\nimport Foundation\n\npublic let GIT_HASH: String = \"$version\""

echo "$filesource" > Sources/DBCO/Generated/GitHash.swift

touch Sources/DBCO/Generated/GitHash.swift

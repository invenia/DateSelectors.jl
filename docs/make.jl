using Documenter, DateSamplers

makedocs(;
    modules=[DateSamplers],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://gitlab.invenia.ca/invenia/DateSamplers.jl/blob/{commit}{path}#L{line}",
    sitename="DateSamplers.jl",
    authors="Invenia Technical Computing Corporation",
    assets=[
        "assets/invenia.css",
        "assets/logo.png",
    ],
    strict=true,
    html_prettyurls=false,
    checkdocs=:none,
)

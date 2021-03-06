[![Codeship Status for AgentLemon/covershow](https://app.codeship.com/projects/a003275f-d986-420d-9b2c-4e8a5c550c0b/status?branch=master)](https://app.codeship.com/projects/425980)

# Covershow

Provides diff coverage changes by excoveralls.json and commit id to compare to

## Usage

```
MIX_ENV=test mix coveralls.json
mix covershow <commit_id | branch_id>
```

## Examples

```
mix covershow HEAD
mix covershow foobar
mix covershow origin/master
```

## Installation

The package can be installed by adding `covershow` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:covershow, "~> 0.1.0", github: "AgentLemon/covershow", only: :dev}
  ]
end
```

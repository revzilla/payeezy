# Avoid running integration tests all of the time. If you want to run all
# tests, including integration, use mix test --include integration
ExUnit.start()
Application.ensure_all_started(:bypass)

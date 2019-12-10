defmodule ExAwsCredentialProcess.Refresh.BeforeExpiredWithJitterTest do
  use ExUnit.Case
  alias ExAwsCredentialProcess.Refresh.BeforeExpiredWithJitter, as: Strategy

  setup do
    datetimes = %{
      expiration: ~U[2020-01-01T12:00:00Z],
      right_before: ~U[2020-01-01T11:59:00Z],
      right_after: ~U[2020-01-01T12:01:01Z],
      way_before: ~U[2020-01-01T00:00:00Z],
      way_after: ~U[2020-01-01T23:59:59Z],
      a_bit_before: ~U[2020-01-01T11:35:00Z]
    }

    {:ok, [datetimes: datetimes]}
  end

  test "it refreshes if retries > 0", %{datetimes: datetimes} do
    assert Strategy.refresh?(datetimes.expiration, datetimes.right_before, 1)
  end

  test "it refreshes after the expiration", %{datetimes: datetimes} do
    assert Strategy.refresh?(datetimes.expiration, datetimes.right_after, 0)
    assert Strategy.refresh?(datetimes.expiration, datetimes.way_after, 0)
  end

  test "it does not refresh way before the expiration", %{datetimes: datetimes} do
    refute Strategy.refresh?(datetimes.expiration, datetimes.way_before, 0)
  end

  test "it gets more likely to refresh as the expiration approaches", %{datetimes: datetimes} do
    check_count = 10_000

    refreshes_a_bit_before =
      Enum.map(1..check_count, fn _i ->
        Strategy.refresh?(datetimes.expiration, datetimes.a_bit_before, 0)
      end)
      |> Enum.count(& &1)

    assert refreshes_a_bit_before > 0
    assert refreshes_a_bit_before < check_count

    refreshes_right_before =
      Enum.map(1..check_count, fn _i ->
        Strategy.refresh?(datetimes.expiration, datetimes.right_before, 0)
      end)
      |> Enum.count(& &1)

    assert refreshes_right_before > 0
    assert refreshes_right_before < check_count

    assert refreshes_right_before > refreshes_a_bit_before
  end
end

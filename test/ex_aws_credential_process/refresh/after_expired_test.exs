defmodule ExAwsCredentialProcess.Refresh.AfterExpiredTest do
  use ExUnit.Case
  alias ExAwsCredentialProcess.Refresh.AfterExpired, as: Strategy

  setup do
    datetimes = %{
      expiration: ~U[2020-01-01T12:00:00Z],
      right_before: ~U[2020-01-01T11:59:59Z],
      right_after: ~U[2020-01-01T12:01:01Z],
      way_before: ~U[2020-01-01T00:00:00Z],
      way_after: ~U[2020-01-01T23:59:59Z],
      a_bit_before: ~U[2020-01-01T11:55:00Z]
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

  test "it does not refresh before the expiration", %{datetimes: datetimes} do
    refute Strategy.refresh?(datetimes.expiration, datetimes.right_before, 0)
    refute Strategy.refresh?(datetimes.expiration, datetimes.way_before, 0)
    refute Strategy.refresh?(datetimes.expiration, datetimes.a_bit_before, 0)
  end
end

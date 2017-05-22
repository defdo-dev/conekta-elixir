defmodule ConektaTest.PlansTest do
    @moduledoc false

    use ExUnit.Case, async: false
    import Mock
    alias Conekta.Client


    describe "Plans" do

      test "should get all plans" do

        expected_mock = Mocks.PlansMock.get_plans_mock()

        with_mock Client, [get_request: fn(_) -> expected_mock end] do

            {:ok, content} = expected_mock
            assert Poison.decode(content.body, as: %Conekta.PlansResponse{}) == Conekta.Plans.plans()

        end

      end

      test "should get a plan by passong it's ID'" do

        expected_mock = Mocks.PlansMock.get_find_mock()
        with_mock Client, [get_request: fn(_) -> expected_mock end] do

            {:ok, content} = expected_mock
            assert Poison.decode(content.body, as: %Conekta.PlansFindResponse{}) == Conekta.Plans.find("plan_2")

        end


      end

    end
  
end
defmodule OrbWasmtime.Wasm do
  @moduledoc """
  Take a WebAssembly module and list its exports or call a one-shot function.
  """

  alias OrbWasmtime.Wasm.Decode
  alias OrbWasmtime.Rust

  alias __MODULE__

  defmacro __using__(_) do
    quote location: :keep do
      use Orb
      import Orb
      alias Orb.{I32, F32}
      require Orb.I32

      require Logger
      # TODO: allow use Wasm.Instance?
      # alias ComponentsGuide.Wasm.Instance

      # @on_load :validate_definition!
      # @after_compile __MODULE__

      # def __after_compile__(_env, _bytecode) do
      #   validate_definition!()
      # end

      # FIXME: this blows up
      # def validate_definition! do
      #   ComponentsGuide.Wasm.validate_definition!(__MODULE__.to_wat())
      # end

      def to_wasm() do
        Wasm.wat2wasm(__MODULE__)
      end

      def exports() do
        Wasm.list_exports(__MODULE__)
      end

      def import_types() do
        Wasm.list_import_types(__MODULE__)
      end

      def start() do
        # if Module.defines?(__MODULE__, {:to_wat, 0}, :def) do
        try do
          # Wasm.Instance.run(__MODULE__)
          Wasm.run_instance(__MODULE__)
        rescue
          x in [RuntimeError] ->
            # IO.puts(__MODULE__.to_wat())
            Logger.error(__MODULE__.to_wat())
            raise x
        end

        # end
      end

      defoverridable start: 0
    end
  end

  def list_exports(source) do
    source =
      case process_source(source) do
        {:wat, _} = value -> value
        other -> {:wat, other}
      end

    Rust.wasm_list_exports(source)
  end

  def grouped_exports(source) do
    exports = list_exports(source)

    for export <- exports, reduce: %{global: %{}, memory: %{}, func: %{}} do
      acc ->
        type = elem(export, 0)
        name = elem(export, 1)
        put_in(acc, [type, name], export |> Tuple.delete_at(0) |> Tuple.delete_at(0))
    end
  end

  def list_import_types(source) do
    source =
      case process_source(source) do
        {:wat, _} = value -> value
        other -> {:wat, other}
      end

    case Rust.wasm_list_imports(source) do
      {:error, reason} -> raise reason
      other -> other
    end
  end

  def wat2wasm(source), do: process_source(source) |> Rust.wat2wasm()

  def to_wasm(source), do: wat2wasm(source)

  def validate_definition!(source) do
    source = {:wat, source}

    case Rust.validate_module_definition(source) do
      {:error, reason} -> raise reason
      _ -> nil
    end
  end

  def call(source, f) do
    call_apply(source, f, [])
  end

  def call(source, f, a) do
    call_apply(source, f, [a])
  end

  def call(source, f, a, b) do
    call_apply(source, f, [a, b])
  end

  def call(source, f, a, b, c) do
    call_apply(source, f, [a, b, c])
  end

  def capture(source, f, arity) do
    # call = Function.capture(__MODULE__, :call, arity + 2)
    case arity do
      0 -> fn -> call(source, f) end
      1 -> fn a -> call(source, f, a) end
      2 -> fn a, b -> call(source, f, a, b) end
      3 -> fn a, b, c -> call(source, f, a, b, c) end
    end
  end

  def call_apply(source, f, args) do
    args = Enum.map(args, &transform32/1)
    call_apply_raw(source, f, args)
  end

  defp call_apply_raw(source, f, args) do
    f = to_string(f)
    process_source(source) |> Rust.wasm_call(f, args) |> Wasm.Decode.process_list_result()
  end

  # defp transform32(a)
  defp transform32(a), do: Decode.transform32(a)

  def call_string(source, f), do: process_source(source) |> Rust.wasm_call_i32_string(f, [])

  def call_string(source, f, a),
    do: process_source(source) |> Rust.wasm_call_i32_string(f, [a])

  def call_string(source, f, a, b),
    do: process_source(source) |> Rust.wasm_call_i32_string(f, [a, b])

  def steps(source, steps) do
    wat = process_source(source)
    results = wat |> Rust.wasm_steps(steps)

    case results do
      {:error, reason} ->
        {:error, reason, wat}

      results when is_list(results) ->
        for result <- results do
          case result do
            [] -> nil
            list when is_list(list) -> IO.iodata_to_binary(list)
            other -> other
          end
        end
    end
  end

  defmodule FuncImport do
    defstruct unique_id: 0,
              module_name: "",
              name: "",
              param_types: [],
              result_types: [],
              # do: fn -> nil end
              do: &Function.identity/1
  end

  defmodule ReplyServer do
    use GenServer

    def start_link(imports) when is_list(imports) do
      case imports do
        [] ->
          # pid = :erlang.alias()
          # :erlang.unalias(pid)
          # pid

          # Process.spawn(fn -> nil end, [])

          GenServer.start_link(__MODULE__, imports)

        imports ->
          GenServer.start_link(__MODULE__, imports)
      end
    end

    @impl true
    def init(imports) do
      # IO.puts("Starting ReplyServer")
      # IO.inspect(imports)
      {:ok, %{imports: imports}}
    end

    # @impl true
    # def handle_info({:set_instance, instance}, imports) do
    #   {:noreply, %{state | instance: instance}}
    # end

    @impl true
    def handle_call({:started_instance, instance}, _from, state) do
      # %{state | instance: instance}
      state = put_in(state[:instance], instance)
      {:reply, :ok, state}
    end

    @impl true
    def handle_info(
          {:reply_to_func_call_out, func_id, resource, term},
          state = %{imports: imports}
        ) do
      # IO.inspect(func_id, label: "reply_to_func_call_out func_id")
      # IO.inspect(resource, label: "reply_to_func_call_out resource")

      {handler, params_arity} =
        imports
        |> Enum.find_value(fn
          %FuncImport{unique_id: ^func_id, do: handler, param_types: nil} ->
            {handler, 0}

          %FuncImport{unique_id: ^func_id, do: handler, param_types: params}
          when is_atom(params) ->
            {handler, 1}

          %FuncImport{unique_id: ^func_id, do: handler, param_types: params}
          when is_tuple(params) ->
            {handler, tuple_size(params)}

          %FuncImport{unique_id: ^func_id, do: handler, param_types: params}
          when is_list(params) ->
            {handler, length(params)}

          _ ->
            nil
        end) ||
          raise "Expected imported function #{func_id} to be provided."

      # IO.inspect(handler, label: "reply_to_func_call_out found handler")
      # IO.inspect(term, label: "reply_to_func_call_out term")

      # IO.inspect(handler, label: "reply_to_func_call_out found func")

      # TODO: wrap in try/catch
      # and call wasm_call_out_reply_failure when it fails.
      # TODO: pass correct params
      # TODO: pass instance to func, so it can read memory

      input = Wasm.Decode.process_list_result(term)

      args =
        case input do
          input when is_tuple(input) -> Tuple.to_list(input)
          input -> List.wrap(input)
        end

      params_plus_caller_arity = params_arity + 1

      output =
        case Function.info(handler, :arity) do
          {:arity, ^params_arity} ->
            apply(handler, args)

          {:arity, ^params_plus_caller_arity} ->
            apply(handler, [resource | args])

          {:arity, arity} ->
            raise "Expected import callback to have arity #{params_arity} or #{params_plus_caller_arity}, instead have #{arity}."
        end

      # output = output |> List.wrap() |> Enum.map(&Decode.transform32/1)

      output =
        case output do
          nil -> []
          t when is_tuple(t) -> t |> Tuple.to_list() |> Enum.map(&Decode.transform32/1)
          value -> [Decode.transform32(value)]
        end

      # IO.inspect(output, label: "reply_to_func_call_out output")
      Rust.wasm_call_out_reply(resource, output)

      {:noreply, state}
    end
  end

  defp process_imports(import_types, imports) do
    # {"http", "get", {:func, %{params: [:i32], results: [:i32]}}}

    imports =
      Map.new(imports, fn {mod, name, func} ->
        {{Atom.to_string(mod), Atom.to_string(name)}, func}
      end)

    for {{mod, name, {:func, func_type}}, index} <- Enum.with_index(import_types) do
      %{params: params, results: results} = func_type
      func = Map.fetch!(imports, {mod, name})

      {:arity, callback_arity} = Function.info(func, :arity)
      params_count = Enum.count(params)

      if params_count != callback_arity and params_count + 1 != callback_arity do
        IO.inspect(IEx.Info.info(params_count))
        IO.inspect(IEx.Info.info(callback_arity))
        IO.inspect(callback_arity, label: "callback arity")
        IO.inspect(params_count, label: "params count")
        IO.inspect(callback_arity == params_count)

        raise "Function arity #{inspect(callback_arity)} must match WebAssembly params count #{inspect(params_count)}."
      end

      %FuncImport{
        unique_id: index,
        module_name: mod,
        name: name,
        param_types: params,
        result_types: results,
        do: func
      }
    end
  end

  def run_instance(source, imports \\ []) do
    import_types = list_import_types(source)
    imports = process_imports(import_types, imports)

    {:ok, pid} = ReplyServer.start_link(imports)
    {identifier, source} = process_source2(source)
    instance = Rust.wasm_run_instance(source, identifier, imports, pid)

    GenServer.call(pid, {:started_instance, instance})

    # receive do
    #   :run_instance_start ->
    #     nil
    # after
    #   5000 ->
    #     IO.puts(:stderr, "No message in 5 seconds")
    # end

    instance
  end

  defp get_instance_handle(%{handle: handle}), do: handle
  defp get_instance_handle(instance), do: instance

  def instance_get_global(instance, global_name),
    do:
      Rust.wasm_instance_get_global_i32(
        get_instance_handle(instance),
        to_string(global_name)
      )

  def instance_set_global(instance, global_name, new_value),
    do:
      Rust.wasm_instance_set_global_i32(
        get_instance_handle(instance),
        to_string(global_name),
        new_value
      )

  defp do_instance_call(instance, f, args) do
    f = to_string(f)
    args = Enum.map(args, &transform32/1)
    # Rust.wasm_instance_call_func(instance, f, args)
    get_instance_handle(instance)
    |> Rust.wasm_instance_call_func(f, args)
    |> Decode.process_term_result()
  end

  # def instance_call(instance, f), do: Rust.wasm_instance_call_func(instance, f)
  def instance_call(instance, f), do: do_instance_call(instance, f, [])
  def instance_call(instance, f, a), do: do_instance_call(instance, f, [a])
  def instance_call(instance, f, a, b), do: do_instance_call(instance, f, [a, b])
  def instance_call(instance, f, a, b, c), do: do_instance_call(instance, f, [a, b, c])

  defp do_instance_call_returning_string(instance, f, args) do
    f = to_string(f)
    Rust.wasm_instance_call_func_i32_string(get_instance_handle(instance), f, args)
  end

  def instance_call_returning_string(instance, f),
    do: do_instance_call_returning_string(instance, f, [])

  def instance_call_returning_string(instance, f, a),
    do: do_instance_call_returning_string(instance, f, [a])

  def instance_call_returning_string(instance, f, a, b),
    do: do_instance_call_returning_string(instance, f, [a, b])

  def instance_call_returning_string(instance, f, a, b, c),
    do: do_instance_call_returning_string(instance, f, [a, b, c])

  def instance_call_stream_string_chunks(instance, f) do
    Stream.unfold(0, fn n ->
      case instance_call_returning_string(instance, f) do
        "" -> nil
        s -> {s, n + 1}
      end
    end)
  end

  def instance_call_joining_string_chunks(instance, f) do
    instance_call_stream_string_chunks(instance, f) |> Enum.join()
  end

  def instance_cast(instance, f) do
    instance_cast_apply(instance, f, [])
  end

  def instance_cast(instance, f, a) do
    instance_cast_apply(instance, f, [a])
  end

  def instance_cast(instance, f, a, b) do
    instance_cast_apply(instance, f, [a, b])
  end

  def instance_cast(instance, f, a, b, c) do
    instance_cast_apply(instance, f, [a, b, c])
  end

  def instance_cast_apply(instance, f, args) do
    f = to_string(f)
    # args = Enum.map(args, &transform32/1)
    get_instance_handle(instance) |> Rust.wasm_instance_cast_func_i32(f, args)
  end

  def instance_write_i32(instance, memory_offset, value)
      when is_integer(memory_offset) and is_integer(value) do
    Rust.wasm_instance_write_i32(get_instance_handle(instance), memory_offset, value)
  end

  def instance_write_i64(instance, memory_offset, value)
      when is_integer(memory_offset) and is_integer(value) do
    Rust.wasm_instance_write_i64(get_instance_handle(instance), memory_offset, value)
  end

  def instance_write_memory(instance, memory_offset, bytes)
      when is_integer(memory_offset) do
    Rust.wasm_instance_write_memory(get_instance_handle(instance), memory_offset, bytes)
  end

  def instance_write_string_nul_terminated(instance, memory_offset, string)
      when is_integer(memory_offset) do
    Rust.wasm_instance_write_string_nul_terminated(
      get_instance_handle(instance),
      memory_offset,
      string
    )
  end

  def instance_write_string_nul_terminated(instance, global_name, string)
      when is_atom(global_name) do
    memory_offset =
      Rust.wasm_instance_get_global_i32(
        get_instance_handle(instance),
        to_string(global_name)
      )

    Rust.wasm_instance_write_string_nul_terminated(
      get_instance_handle(instance),
      memory_offset,
      string
    )
  end

  def instance_read_memory(instance, start, length)
      when is_integer(start) and is_integer(length) do
    Rust.wasm_instance_read_memory(get_instance_handle(instance), start, length)
    |> IO.iodata_to_binary()
  end

  def instance_read_memory(instance, start_global_name, length)
      when is_atom(start_global_name) and is_integer(length) do
    start = Rust.wasm_instance_get_global_i32(instance, to_string(start_global_name))

    Rust.wasm_instance_read_memory(get_instance_handle(instance), start, length)
    |> IO.iodata_to_binary()
  end

  def instance_read_string_nul_terminated(instance, memory_offset)
      when is_integer(memory_offset) do
    Rust.wasm_instance_read_string_nul_terminated(
      get_instance_handle(instance),
      memory_offset
    )
  end

  defp process_source2(string) when is_binary(string), do: {"unknown", {:wat, string}}
  defp process_source2({:wat, string} = value) when is_binary(string), do: {"unknown", value}
  defp process_source2(atom) when is_atom(atom), do: {to_string(atom), {:wat, atom.to_wat()}}

  defp process_source(source) do
    {_identifier, {:wat, source}} = process_source2(source)
    source
  end
end

defmodule OrbWasmtime.Wasm.Decode do
  def transform32(a) when is_integer(a) and a < 0, do: {:i32, a}
  def transform32(a) when is_integer(a), do: {:u32, a}
  def transform32(a) when is_float(a), do: {:f32, a}
  def transform32(a) when is_tuple(a), do: a

  defp process_value({:i32, a}), do: a
  defp process_value({:i64, a}), do: a
  defp process_value({:f32, a}), do: a
  defp process_value({:f64, a}), do: a

  def process_list_result([]), do: nil
  def process_list_result([a]), do: process_value(a)

  def process_list_result(multiple_items) when is_list(multiple_items),
    do: multiple_items |> Enum.map(&process_value/1) |> List.to_tuple()

  def process_list_result({:error, "failed to parse WebAssembly module"}), do: {:error, :parse}
  def process_list_result({:error, s}), do: {:error, s}

  def process_term_result(nil), do: nil
  def process_term_result({:i32, a}), do: a
  def process_term_result({:i64, a}), do: a
  def process_term_result({:f32, a}), do: a
  def process_term_result({:f64, a}), do: a

  def process_term_result({:error, "failed to parse WebAssembly module"}), do: {:error, :parse}
  def process_term_result({:error, s}), do: {:error, s}

  # I’m not happy with how the previous two cases {:i32, a} and this are both tuples. It’s confusing.
  def process_term_result(tuple) when is_tuple(tuple) do
    tuple |> Tuple.to_list() |> Enum.map(&process_value/1) |> List.to_tuple()
  end
end

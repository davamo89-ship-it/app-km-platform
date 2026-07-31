using Platform.SharedKernel.Errors;

namespace Platform.SharedKernel.Results;

public sealed class Result<TValue> : Result
{
    private readonly TValue? _value;

    private Result(TValue? value, bool isSuccess, Error error)
        : base(isSuccess, error)
    {
        _value = value;
    }

    public TValue Value
    {
        get
        {
            if (IsFailure)
            {
                throw new InvalidOperationException(
                    "The value of a failed result cannot be accessed.");
            }

            return _value!;
        }
    }

    public static Result<TValue> Success(TValue value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return new Result<TValue>(
            value,
            true,
            Error.None);
    }

    public new static Result<TValue> Failure(Error error)
    {
        ArgumentNullException.ThrowIfNull(error);

        return new Result<TValue>(
            default,
            false,
            error);
    }

    public static implicit operator Result<TValue>(TValue value)
    {
        return value is not null
            ? Success(value)
            : Failure(Error.NullValue);
    }
}